(load-file "./parser.el")

(ert-deftest parser-tests/get-matching-closing-brackets ()
  (let ((lexer-output (lexer/lex "((foo bar) baz)")))
    (should (equal
             (parser/get-matching-closing-bracket 0)
             6))
    (should (equal
             (parser/get-matching-closing-bracket 1)
             4))))

(ert-deftest parser-tests/is-function ()
  (let ((lexer-output (lexer/lex "(number) => void"))
        (i 0))
    (should (equal
             (parser/is-function)
             t))))

(ert-deftest parser-tests/is-not-function ()
  (let ((lexer-output (lexer/lex "(number)"))
        (i 0))
    (should (equal
             (parser/is-function)
             nil))))

(defun parser-tests/check-parser (str ast)
  (should (equal (parser/parse str) ast)))

(ert-deftest parser-tests/alias-type ()
  (let ((str "type A = B")
        (ast '(((name . "A")
                (type . "alias")
                (value
                 ((type . "name")
                  (value . "B")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/generic-alias-type ()
  (let ((str "type Foo<A, B> = A | B")
        (ast '(((name . "Foo")
                (type . "alias")
                (generic
                 (entries
                  (((type . "name")
                    (value . "A"))
                   ((type . "name")
                    (value . "B")))))
                (value
                 ((type . "name")
                  (value . "A")
                  (union
                   ((type . "name")
                    (value . "B")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/opaque-alias-type ()
  (let ((str "opaque type A = B")
        (ast '(((name . "A")
                (type . "alias")
                (is-opaque . t)
                (value
                 ((type . "name")
                  (value . "B")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/class-type ()
  (let ((str "class A")
        (ast '(((name . "A")
                (type . "class")))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/generic-class-type ()
  (let ((str "class Foo<A, B>")
        (ast '(((name . "Foo")
                (type . "class")
                (generic
                 (entries
                  (((type . "name")
                    (value . "A"))
                   ((type . "name")
                    (value . "B")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/interface-type ()
  (let ((str "interface A")
        (ast '(((name . "A")
                (type . "interface")))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/tuple-type ()
  (let ((str "[Type1, Type2]")
        (ast '(((type . "tuple")
                (value
                 (((type . "name")
                   (value . "Type1"))
                  ((type . "name")
                   (value . "Type2"))))))))
    (parser-tests/check-parser str ast)))


(ert-deftest parser-tests/grouping-arrays-type ()
  (let ((str "(number | void[])[]")
        (ast '(((type . "group")
                (value
                 ((type . "name")
                  (value . "number")
                  (union
                   ((type . "name")
                    (value . "void")
                    (is-array . t)))))
                (is-array . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/function-array-type ()
  (let ((str "((number) => void[])[]")
        (ast '(((type . "group")
                (value
                 ((type . "function")
                  (arguments
                   (((key)
                     (value
                      ((type . "name")
                       (value . "number"))))))
                  (return-value
                   ((type . "name")
                    (value . "void")
                    (is-array . t)))))
                 (is-array . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/union-type ()
  (let ((str "Type1 | Type2 | Type3")
        (ast '(((type . "name")
                (value . "Type1")
                (union ((type . "name")
                        (value . "Type2")
                        (union ((type . "name")
                                (value . "Type3")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/intersection-type ()
  (let ((str "Type1 & Type2 & Type3")
        (ast '(((type . "name")
                (value . "Type1")
                (intersection ((type . "name")
                        (value . "Type2")
                        (intersection ((type . "name")
                                (value . "Type3")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/function-type-empty-args ()
  (let ((str "() => void")
        (ast '(((type . "function")
                (arguments nil)
                (return-value
                 ((type . "name")
                  (value . "void")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/function-type-unamed-args ()
  (let ((str "(number, string) => boolean")
        (ast '(((type . "function")
                (arguments
                 (((key)
                   (value
                    ((type . "name")
                     (value . "number"))))
                  ((key)
                   (value
                    ((type . "name")
                     (value . "string"))))))
                (return-value
                 ((type . "name")
                  (value . "boolean")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/function-type-mixed-args ()
  (let ((str "(number, foo: string) => boolean")
        (ast '(((type . "function")
                (arguments
                 (((key)
                   (value
                    ((type . "name")
                     (value . "number"))))
                  ((key . "foo")
                   (value
                    ((type . "name")
                     (value . "string"))))))
                (return-value
                 ((type . "name")
                  (value . "boolean")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/function-type-names-args ()
  (let ((str "(arg1: number, arg2: string) => boolean")
        (ast '(((type . "function")
                (arguments
                 (((key . "arg1")
                   (value
                    ((type . "name")
                     (value . "number"))))
                  ((key . "arg2")
                   (value
                    ((type . "name")
                     (value . "string"))))))
                (return-value
                 ((type . "name")
                  (value . "boolean")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/generic-function-type ()
  (let ((str "<A, B>(a) => void")
        (ast '(((type . "function")
                (arguments
                 (((key)
                   (value
                    ((type . "name")
                     (value . "a"))))))
                (return-value
                 ((type . "name")
                  (value . "void")))
                (generic
                 (entries
                  (((type . "name")
                    (value . "A"))
                   ((type . "name")
                    (value . "B")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/array-type ()
  (let ((str "Type[]")
        (ast '(((type . "name")
                (value . "Type")
                (is-array . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/dict-array-type ()
  (let ((str "{foo: bar}[]")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "bar"))))))
                (is-array . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/generic-array-type ()
  (let ((str "foo<bar>[]")
        (ast '(((type . "name")
                (value . "foo")
                (generic (entries (((type . "name")
                                    (value . "bar")))))
                (is-array . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/array-type-with-union ()
  (let ((str "Type1[] | number")
        (ast '(((type . "name")
                (value . "Type1")
                (is-array . t)
                (union ((type . "name")
                        (value . "number")))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/maybe-type ()
  (let ((str "?Type1")
        (ast '(((type . "name")
                (value . "Type1")
                (is-optional . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/maybe-type-dict-key ()
  (let ((str "{ foo: ?bar }")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "bar")
                                   (is-optional . t))))))))))
    (message "%s" ast)
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/empty-dict ()
  (let ((str "{}")
        (ast '(((type . "dict")
                (entries nil)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/single-key-dict ()
  (let ((str "{ foo: 1.122 }")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "1.122"))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/multiple-keys-dict ()
  (let ((str "{ foo: 1.122, bar: string }")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "1.122"))))
                          ((key . "bar")
                           (value ((type . "name")
                                   (value . "string"))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/multiple-keys-exact-dict ()
  (let ((str "{| foo: 1.122, bar: string |}")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "1.122"))))
                          ((key . "bar")
                           (value ((type . "name")
                                   (value . "string"))))))
                (is-exact . t)))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/immutable-key-dict ()
  (let ((str "{ +foo: bar }")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "bar")))
                           (is-immutable . t))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/indexer-key-dict ()
  (let ((str "{ [foo]: bar }")
        (ast '(((type . "dict")
                (entries
                 (((key
                    ((key)
                     (value
                      ((type . "name")
                       (value . "foo")))))
                (is-indexer-prop . t)
                (value
                 ((type . "name")
                  (value . "bar"))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/named-indexer-key-dict ()
  (let ((str "{ [foo: you]: bar }")
        (ast '(((type . "dict")
                (entries
                 (((key
                    ((key . "foo")
                     (value
                      ((type . "name")
                       (value . "you")))))
                   (is-indexer-prop . t)
                   (value
                    ((type . "name")
                     (value . "bar"))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/nested-dict ()
  (let ((str "{ foo: 1.122, bar: { a: Type1, b: Type2 } }")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "1.122"))))
                          ((key . "bar")
                           (value ((type . "dict")
                                   (entries (((key . "a")
                                              (value ((type . "name")
                                                      (value . "Type1"))))
                                             ((key . "b")
                                              (value ((type . "name")
                                                      (value . "Type2")))))))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/single-arg-generic-type ()
  (let ((str "Type<string>")
        (ast '(((type . "name")
                (value . "Type")
                (generic (entries (((type . "name")
                                    (value . "string")))))))))
    (parser-tests/check-parser str ast)))


(ert-deftest parser-tests/multiple-args-generic-type ()
  (let ((str "Type1<string, Type2<number, string>, number>")
        (ast '(((type . "name")
                (value . "Type1")
                (generic (entries (((type . "name")
                                    (value . "string"))
                                   ((type . "name")
                                    (value . "Type2")
                                    (generic (entries (((type . "name")
                                                        (value . "number"))
                                                       ((type . "name")
                                                        (value . "string"))))))
                                   ((type . "name")
                                    (value . "number")))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest parser-tests/big-test ()
  (let ((str "{foo: 1.122, bar: {a: hi<FooType<{i: am, thomas: binetruy<string>}, string>, boolean>, b: what}, hello: what}")
        (ast '(((type . "dict")
                (entries (((key . "foo")
                           (value ((type . "name")
                                   (value . "1.122"))))
                          ((key . "bar")
                           (value ((type . "dict")
                                   (entries (((key . "a")
                                              (value ((type . "name")
                                                      (value . "hi")
                                                      (generic (entries (((type . "name")
                                                                          (value . "FooType")
                                                                          (generic (entries (((type . "dict")
                                                                                              (entries (((key . "i")
                                                                                                         (value ((type . "name")
                                                                                                                 (value . "am"))))
                                                                                                        ((key . "thomas")
                                                                                                         (value ((type . "name")
                                                                                                                 (value . "binetruy")
                                                                                                                 (generic (entries (((type . "name")
                                                                                                                                     (value . "string")))))))))))
                                                                                             ((type . "name")
                                                                                              (value . "string"))))))
                                                                         ((type . "name")
                                                                          (value . "boolean"))))))))
                                             ((key . "b")
                                              (value ((type . "name")
                                                      (value . "what")))))))))
                          ((key . "hello")
                           (value ((type . "name")
                                   (value . "what"))))))))))
    (parser-tests/check-parser str ast)))

(ert-deftest lexer-tests/is-digit ()
  (should (equal (lexer/is-digit (string-to-char "2")) 0))
  (should (equal (lexer/is-digit (string-to-char "*")) nil)) ; special char not allowed
  (should (equal (lexer/is-digit (string-to-char "b")) nil))) ; letters not allowed

(ert-deftest lexer-tests/is-type ()
  (should (equal (lexer/is-type (string-to-char "2")) nil)) ; cannot start by number
  (should (equal (lexer/is-type (string-to-char "$")) 0)) ; allowed special char
  (should (equal (lexer/is-type (string-to-char "_")) 0)) ; allowed special char
  (should (equal (lexer/is-type (string-to-char "&")) nil)) ; not an allowed special char
  (should (equal (lexer/is-type (string-to-char "s")) 0))) ; can start with letter

(ert-deftest lexel-tests/is-special-char ()
  (should (equal (lexer/is-special-char (string-to-char "{")) 0))
  (should (equal (lexer/is-special-char (string-to-char "}")) 0))
  (should (equal (lexer/is-special-char (string-to-char ":")) 0))
  (should (equal (lexer/is-special-char (string-to-char "=")) 0))
  (should (equal (lexer/is-special-char (string-to-char "<")) 0))
  (should (equal (lexer/is-special-char (string-to-char ">")) 0))
  (should (equal (lexer/is-special-char (string-to-char ",")) 0))
  (should (equal (lexer/is-special-char (string-to-char "[")) 0))
  (should (equal (lexer/is-special-char (string-to-char "]")) 0))
  (should (equal (lexer/is-special-char (string-to-char "?")) 0))
  (should (equal (lexer/is-special-char (string-to-char "+")) 0))
  (should (equal (lexer/is-special-char (string-to-char "(")) 0))
  (should (equal (lexer/is-special-char (string-to-char ")")) 0))
  (should (equal (lexer/is-special-char (string-to-char "s")) nil)))

(ert-deftest lexer-tests/lex-special-char ()
  (let ((str "[]{}:=<>,|&?+()")
        (lexer-output '(((type . "special-char")
                         (value . "["))
                        ((type . "special-char")
                         (value . "]"))
                        ((type . "special-char")
                         (value . "{"))
                        ((type . "special-char")
                         (value . "}"))
                        ((type . "special-char")
                         (value . ":"))
                        ((type . "special-char")
                         (value . "="))
                        ((type . "special-char")
                         (value . "<"))
                        ((type . "special-char")
                         (value . ">"))
                        ((type . "special-char")
                         (value . ","))
                        ((type . "special-char")
                         (value . "|"))
                        ((type . "special-char")
                         (value . "&"))
                        ((type . "special-char")
                         (value . "?"))
                        ((type . "special-char")
                         (value . "+"))
                        ((type . "special-char")
                         (value . "("))
                        ((type . "special-char")
                         (value . ")")))))
    (should (equal (lexer/lex str) lexer-output))))

(ert-deftest lexer-tests/lex-words ()
  (let ((str "foo bar type class interface opaque")
        (lexer-output '(((type . "type")
                         (value . "foo"))
                        ((type . "type")
                         (value . "bar"))
                        ((type . "keyword")
                         (value . "type"))
                        ((type . "keyword")
                         (value . "class"))
                        ((type . "keyword")
                         (value . "interface"))
                        ((type . "keyword")
                         (value . "opaque")))))
    (should (equal (lexer/lex str) lexer-output))))

(ert-deftest lexer-tests/lex-numbers ()
  (let ((str "1 44.23 344")
        (lexer-output '(((type . "number")
                         (value . "1"))
                        ((type . "number")
                         (value . "44.23"))
                        ((type . "number")
                         (value . "344")))))
    (should (equal (lexer/lex str) lexer-output))))
