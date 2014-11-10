;;; cpp-buf-utils.el --- navigation and ido expansions for common C++ namespace and include operations

;; Copyright (C) 2014  John P. Feltz

;; Author: John P. Feltz <jfeltz@gmail.com>
;; Keywords: languages, convenience, tools

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(defvar c-navigate-include-start-point nil)

(defvar cpp-dependencies 
  nil
  (concat 
    "The defined namespace/include depedencies for c++ projects.\n"
    "See documentation on cpp-pragmatics for format.")
  )

(defun last-occurance (expr)
  "return the last occurance without modifying the editor env"
  (save-excursion
    (goto-char (point-max))
    (search-backward-regexp (concat "^" expr) (point-min) t)))

(defun c-navigate-include ()
  (setq c-navigate-include-start-point (point))
  (let ((last (last-occurance "#include")))
    (when last
      (progn 
        (goto-char last))))
        (move-beginning-of-line nil))

(defun c-navigate-include-return ()
  "Return to the non-include point we were at before going to the include list."
  (when c-navigate-include-start-point
    (goto-char c-navigate-include-start-point)))

(defun c-include-displacement (&optional away)
  "visit or unvisit the include block based on arg" 
  (if away (c-navigate-include-return) (c-navigate-include)))

(defun c-include-visit ()
  "visit c/c++ includes"
  (interactive)
  (c-include-displacement nil))

(defun c-include-unvisit ()
  (interactive)
  "move away from the c/c++ includes to last known position, or same"
  (c-include-displacement t)
  )

(defun cpp-dep-ns (namespace &optional alias)
 "<namespace> <possible nil namespace alias>"
 (values namespace alias)
 )

(defun dep (name header nl)
 "args are: <fuzzy searchable str> <a list of header defs> <a list of namespace defs>"
 (list name header nl))

(defun cpp-dep-headers (&rest args) args)
(defun cpp-deps (&rest args) args)
(defun include (p) 
  "takes a literal string to be included with #include str"
  (values p)
)

(defun include-path (path)
  "takes a path, and returns defintion for #include \"foobar.hpp\""
  (include (concat "\"" path "\""))
  )

(defun include-bkt (kw)
  "takes a keyword, and returns defintion for #include <foobarp>"
  (include (concat "<" kw ">"))
  )

(defun namespaces (&rest args) args)
(defun namespace (n) (list n nil))
(defun namespace-alias (n a) (values n a))

(defun diagnostic (msg) (message "%s" (concat "cpp-buf: " msg)))

(defun insert-includes (includes)
  "starting at current line pos, insert the include in defined list" 
  ; pre-condition:
  ;   cursor is at next line after include list 
  (unless (not includes)  
    (move-beginning-of-line nil)
    (insert "\n") (forward-line -1) ; shove rest down one line 
    (insert "#include " (car includes)) ; insertion
    ; move down to put in pre-condition
    (forward-line 1) 
    (insert-includes (cdr includes))
    )
  )

(defun namespace-insert (namespace-def)
  "produce a namespace insert from the definition"
  (let
      ((n (car namespace-def)) (alias (car (cdr namespace-def))))
  (if
     (not alias)
     (concat "using namespace " n ";")
     (concat "namespace " alias " = " n ";")
    )))

(defun insert-namespaces (nl)
  "starting at current line pos, insert the namespace defined" 
  ; pre-condition:
  ;   cursor is at next line after namespace list 
  (unless (not nl)  
    (move-beginning-of-line nil)
    (insert "\n") (forward-line -1) ; shove rest down one line 
    (insert (namespace-insert (car nl))) ; insertion
    ; move down to put in pre-condition
    (forward-line 1) 
    (insert-namespaces (cdr nl))
    )
  )

(defun update-block (f jobs sentinel name)
  (let ((last (last-occurance sentinel)))
    (if (not last) 
        (diagnostic (concat "unable to locate " name " block"))
        (progn 
          (goto-char last)
          (forward-line 1)
          (move-beginning-of-line nil))
          (funcall f jobs))))

(defun update-includes (includes)
  "Update buffer on given list of include files, e.g. (\"d.hpp\"
\"a/b/c.hpp\"). If include block cannot be found to be updated, print
failure"
  (if includes (update-block 'insert-includes includes "#include" "include")))

(defun update-namespaces (nl) 
  "Update buffer on given list of namespace definitions. If namespace list
block cannot be found to be updated, print failure"
  (if nl (update-block 'insert-namespaces nl "using" "namespace")))

(defun from-selection (k)
  "manipulate the buffer from a dependency key selection" 
  (progn 
    (update-includes ; the list of include defs
     (car (cdr (assoc k cpp-dependencies))))
    (message (format "%s" (assoc k cpp-dependencies)))
    (update-namespaces ; the list of namespace defs
     (car (cdr (cdr (assoc k cpp-dependencies)))))))

(defun to-ido-indexes (def)
  "produce ido-indexes from the def"
  (mapcar 'car cpp-dependencies))

(defun cpp-dep-add ()
  "launch the ido selection of dependencies to add to the buffer"
  (interactive)
  (save-excursion 
    (from-selection
     (ido-completing-read
     "add c++ dep: "
     (to-ido-indexes cpp-dependencies)))))

(defun from-kw (kw) (dep kw (include-bkt kw) ()))

(defun default-cpp-dependencies ()
  "a dep list for common C++ cases, and can be bound to the cpp-dependencies var"
  (append (std-cpp11-deps) (boost-deps))) 

(defun boost-deps () 
  (cpp-deps
   (dep "boost ns" nil (namespace "boost"))
   (dep
     "boost program options"
     (include-bkt "boost/program_options.hpp")
     (namespaces
       (namespace-alias "boost::program_options" "po")))
   (dep
     "boost spirit"
     (include-bkt "boost/spirit/include/qi.hpp")
     (namespaces
      (namespace-alias "boost::spirit::qi" "qi")))
   (dep
     "boost assert"
     (include-bkt "boost/assert.hpp")
     (namespaces nil))
   (dep
     "boost optional"
     (include-bkt "boost/optional.hpp")
     (namespaces nil))
   (dep
     "boost asio"
     (include-bkt "boost/asio.hpp")
     (namespaces (namespace "boost::asio::ip::tcp")))))

(defun std-cpp11-deps () 
 "a dep list for STL11 includes"
 (let 
     ((includes 
     '("algorithm"
        "array"
        "atomic"
        "bitset"
        "cassert"
        "ccomplex"
        "cctype"
        "cerrno"
        "cfenv"
        "cfloat"
        "chrono"
        "cinttypes"
        "climits"
        "clocale"
        "cmath"
        "complex"
        "condition_variable"
        "csetjmp"
        "csignal"
        "scoped_allocator"
        "set"
        "shared_mutex"
        "sstream"
        "stack"
        "stdexcept"
        "streambuf"
        "string"
        "system_error"
        "thread"
        "tuple"
        "typeindex"
        "typeinfo"
        "type_traits"
        "unordered_map"
        "unordered_set"
        "utility"
        "valarray"
        "vector"
        "cstdalign"
        "cstdarg"
        "cstdbool"
        "cstddef"
        "cstdint"
        "cstdio"
        "cstdlib"
        "cstring"
        "ctgmath"
        "ctime"
        "cwchar"
        "cwctype"
        "debug"
        "deque"
        "exception"
        "experimental"
        "forward_list"
        "fstream"
        "functional"
        "future"
        "initializer_list"
        "iomanip"
        "ios"
        "iosfwd"
        "iostream"
        "istream"
        "iterator"
        "limits"
        "list"
        "locale"
        "map"
        "memory"
        "mutex"
        "new"
        "numeric"
        "ostream"
        "queue"
        "random"
        "ratio"
        "regex")))
   (mapcar 'from-kw includes)))

(provide 'cpp-buf-utils)
