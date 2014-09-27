cpp-buf-utils
==============
This Emacs library provides some basic methods for navigating and
populating a c++ buffer with project dependencies. Emphasis is on
configuring to the project at hand with just Elisp, rather than
relying on **clang**, or some other c++ file inference engine.

## Setup for Buffer Population
The list, ```cpp-dependencies``` should be set on a per project basis,
and *cpp-buf-utils* provides a set of small dsl-like functions
for creating it. As an example: 
```lisp
(setq cpp-dependencies
  (cpp-deps
   (dep "iostream" (include-bkt "iostream"))
   (dep "vector" (include-bkt "vector")
   (dep "boost ns" nil (namespace "boost"))
   (dep
	 "boost program options"
	 (include-path "boost/program_options.hpp")
	 (namespaces
	   (namespace-alias "boost::program_options" "po")))
   (dep
	 "boost spirit"
	 (include-path "boost/spirit/include/qi.hpp")
	 (namespaces
	   (namespace-alias "boost::spirit::qi" "qi"))))))
```

*Legend*
  * ```iostream```, and ```vector``` dep's define expansions for the STL *#include <iostream>* and *<vector>*
  respectfully
  * ```boost ns``` define a namespace expansion for a ```using namespace boost;``` expression.
  * ```boost program options``` and ```boost spirit``` define both an #include, and namespace alias for *boost::program_options*

As a side note, cpp-buf-deps also provides a list of common dependencies by default, see ```(std-cpp-deps)``` and ```(default-cpp-dependencies)```.

# Buffer Operation 
Then one can add members from this to the section by ido selection with:
```
M-x cpp-dep-add 
```
Which results in the minibuffer options:
```
add c++ dep: { iostream | vector | boost ns | boost program options | boost spirit } 
```

ido selecting ```iostream``` in this case results in ```#include <iostream>``` being included in
the header section of the file.

**A Note on how cpp-buf-utils searchers for addition points**

cpp-buf-utils expects a *#include* section to already exist so it can find
the insertion point, and similarly, a using declaration identifies the insertion
point for namspaces. I'm considering adding a feature to use the cursor position
when it is otherwise ambiguous. 

# Buffer Navigation
```elisp
M-x c-include-visit
```
To jump to the last ```#include <..>``` definition. And:

```elisp
M-x c-include-unvisit
```
to return to the last cursor position.

# Installation
```lisp
(add-to-list 'load-path "~/path/to/cpp-buf-utils/")
(require 'cpp-buf-utils)
```
