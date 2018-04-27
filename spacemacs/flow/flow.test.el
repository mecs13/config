(load-file "./parser.el")

(defun parser-tests/check-parser (str ast)
  (should (equal (parser/parse str) ast)))

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

(ert-deftest parser-tests/array-type ()
  (let ((str "Type[]")
        (ast '(((type . "name")
                (value . "Type")
                (is-array . t)))))
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
  (should (equal (lexer/is-special-char (string-to-char "s")) nil)))

(ert-deftest lexer-tests/lex-special-char ()
  (let ((str "[{}:=<>,|&?")
        (lexer-output '(((type . "special-char")
                         (value . "["))
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
                         (value . "?")))))
    (should (equal (lexer/lex str) lexer-output))))

(ert-deftest lexer-tests/lex-words ()
  (let ((str "foo bar")
        (lexer-output '(((type . "type")
                         (value . "foo"))
                        ((type . "type")
                         (value . "bar")))))
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
