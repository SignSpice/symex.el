;;; symex-dsl.el --- An evil way to edit Lisp symbolic expressions as trees -*- lexical-binding: t -*-

;; URL: https://github.com/countvajhula/symex.el

;; This program is "part of the world," in the sense described at
;; http://drym.org.  From your perspective, this is no different than
;; MIT or BSD or other such "liberal" licenses that you may be
;; familiar with, that is to say, you are free to do whatever you like
;; with this program.  It is much more than BSD or MIT, however, in
;; that it isn't a license at all but an idea about the world and how
;; economic systems could be set up so that everyone wins.  Learn more
;; at drym.org.

;;; Commentary:
;;
;; Syntax specification for the Symex DSL
;;

;;; Code:


(defun symex--compile-traversal-helper (traversal)
  "Helper function to compile a TRAVERSAL.

This is useful for mapping a compiler macro over a list of
traversal specifications."
  `(symex-traversal ,traversal))

(defmacro symex--compile-protocol (&rest options)
  "Compile a protocol from Symex DSL -> Lisp.

OPTIONS - see underlying Lisp implementation."
  `(symex-make-protocol
    ,@(mapcar 'symex--compile-traversal-helper options)))

(defmacro symex--compile-maneuver (&rest phases)
  "Compile a maneuver from Symex DSL -> Lisp.

PHASES - see underlying Lisp implementation."
  `(symex-make-maneuver
    ,@(mapcar 'symex--compile-traversal-helper phases)))

(defmacro symex--compile-detour (reorientation traversal)
  "Compile a detour from Symex DSL -> Lisp.

REORIENTATION - see underlying Lisp implementation.
TRAVERSAL - see underlying Lisp implementation."
  `(symex-make-detour (symex-traversal ,reorientation)
                      (symex-traversal ,traversal)))

(defmacro symex--compile-circuit (traversal &optional times)
  "Compile a circuit from Symex DSL -> Lisp.

TRAVERSAL - see underlying Lisp implementation.
TIMES - see underlying Lisp implementation."
  `(symex-make-circuit (symex-traversal ,traversal)
                       ,times))

(defun symex--rewrite-precaution-condition (condition)
  "rewrite condition"
  (cond ((symbolp condition)
         (cond ((equal 'final condition)
                'symex--point-at-final-symex-p)
               ((equal 'initial condition)
                'symex--point-at-initial-symex-p)
               ((equal 'first condition)
                'symex--point-at-first-symex-p)
               ((equal 'last condition)
                'symex--point-at-last-symex-p)
               ((equal 'root condition)
                'symex--point-at-root-symex-p)))
        ((equal 'not (car condition))
         `(lambda () (not (,(symex--rewrite-precaution-condition (cadr condition))))))
        ((equal 'at (car condition))
         (symex--rewrite-precaution-condition (cadr condition)))
        (t condition)))

(defun symex--rewrite-precaution-condition-spec (condition-spec)
  "Rewrite DSL syntax to Lisp syntax in a precaution specification.

CONDITION - a condition written in DSL syntax. See underlying Lisp
implementation for more on precaution conditions."
  (cond ((or (equal 'before (car condition-spec))
             (equal 'beforehand (car condition-spec)))
         `(:pre-condition ,(symex--rewrite-precaution-condition (cadr condition-spec))))
        ((or (equal 'after (car condition-spec))
             (equal 'afterwards (car condition-spec)))
         `(:post-condition ,(symex--rewrite-precaution-condition (cadr condition-spec))))))

(defmacro symex--compile-precaution (traversal &rest condition-specs)
  "Compile a precaution from Symex DSL -> Lisp.

TRAVERSAL - see underlying Lisp implementation.
CONDITIONS - conditions to be checked either before or after executing
the traversal -- see underlying Lisp implementation. The conditions may
either be specified purely using the DSL, or could also include custom
lambdas which will be used verbatim.

Conditions to be checked before executing the traversal are specified as:

(beforehand ...)

Conditions to be checked after executing the traversal are specified as:

(afterwards ...)

Checking that we are at a particular node is done via:

(at root/first/last/initial/final)

where root is the root of the current tree, first and last are the first
and last symexes at the current level, and initial and final refer to the
first and last symex in the buffer. These conditions may also be negated:

(not (at ...)).

Alternatively, if a custom condition is desired, it may be specified
directly, e.g.:

(beforehand <procedure>)."
  (append `(symex-make-precaution (symex-traversal ,traversal))
          (apply 'append
                 (mapcar 'symex--rewrite-precaution-condition-spec condition-specs))))

(defmacro symex--compile-move (direction)
  "Compile a move from Symex DSL -> Lisp.

DIRECTION - the direction to move in, which could be one of:
forward, backward, in, or out."
  (cond ((equal 'forward direction)
         '(symex-make-move 1 0))
        ((equal 'backward direction)
         '(symex-make-move -1 0))
        ((equal 'in direction)
         '(symex-make-move 0 1))
        ((equal 'out direction)
         '(symex-make-move 0 -1))))

(defmacro symex-traversal (traversal)
  "Compile a traversal from Symex DSL -> Lisp.

TRAVERSAL could be any traversal specification, e.g. a maneuver,
a detour, a move, etc., which is specified using the Symex DSL."
  (cond ((not (listp traversal)) traversal)  ; e.g. a variable containing a traversal
        ((equal 'protocol (car traversal))
         `(symex--compile-protocol ,@(cdr traversal)))
        ((equal 'maneuver (car traversal))
         `(symex--compile-maneuver ,@(cdr traversal)))
        ((equal 'detour (car traversal))
         `(symex--compile-detour ,@(cdr traversal)))
        ((equal 'circuit (car traversal))
         `(symex--compile-circuit ,@(cdr traversal)))
        ((equal 'precaution (car traversal))
         `(symex--compile-precaution ,@(cdr traversal)))
        ((equal 'move (car traversal))
         `(symex--compile-move ,@(cdr traversal)))))

(defmacro deftraversal (name traversal &optional docstring)
  "Define a symex traversal using the Symex DSL.

NAME is the name of the traversal.  The defined traversal will be
assigned to a variable with this name.
TRAVERSAL is the specification of the traversal in the Symex DSL.
This can be thought of as the 'program' written in the DSL, which
will be compiled into Lisp and can be executed when needed.
An optional DOCSTRING will be used as documentation for the variable
NAME to which the traversal is assigned."
  `(defvar ,name (symex-traversal ,traversal) ,docstring))


(provide 'symex-dsl)
;;; symex-dsl.el ends here
