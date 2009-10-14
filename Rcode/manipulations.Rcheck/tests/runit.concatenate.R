library(RUnit)
#library(manipulations)
#source("concatenate.r")

test.concatenate.rbind.values <- function() {
  a <- array(1:12, c(3,2,2));
  b <- array(11:18, c(2,2,2));
  checkEquals(concatenate(a, b, along=1),
              array(c(1, 2, 3, 11, 12, 4, 5, 6, 13, 14,
                      7, 8, 9, 15, 16, 10, 11, 12, 17, 18), c(5, 2, 2)));
}

test.concatenate.rbind.list.values <- function() {
  a <- array(as.list(1:8), c(2,2,2));
  b <- array(letters[1:4], c(1, 2, 2));

  checkEquals(concatenate(a, b, along=1),
              array(list(1, 2, "a", 3, 4, "b", 5, 6, "c", 7, 8, "d"), c(3, 2, 2)));
}

test.concatenate.3bind.values <- function() {
  a <- array(1:8, c(2, 2, 2));
  b <- array(seq(10,40,10), c(2,2));

  checkEquals(concatenate(a, b, along=3),
              array(c(1:8, seq(10,40,10)), c(2, 2, 3)))
}

## test.concatenate.names <- function() {
##   a <- array(c(foo=1,bar=2,baz=3), c(3, 1));
##   b <- array(c(qux=4,quux=5,quuux=6), c(3, 1));
##   checkEquals(concatenate(a, b, along=1),
##               array(c(foo=1,bar=2,baz=3,qux=4,quux=5,quuux=6), c(6,1)));
##   checkEquals(concatenate(a, b, along=2),
##               array(c(foo=1,bar=2,baz=3,qux=4,quux=5,quuux=6), c(3,2)));
## }


test.concatenate.some.names <- function() {
  a <- structure(c(foo=1,2,baz=3), dim=c(3, 1));
  b <- c(qux=4,quux=5,6);
  checkEquals(concatenate(a, b, along=1),
              array(c(foo=1,2,baz=3,qux=4,quux=5,6), c(6,1)))
  checkEquals(concatenate(a, b, along=2),
              array(c(foo=1,bar=2,baz=3,qux=4,quux=5,6), c(3,2)))
}

test.concatenate.first.rownames <- function() {
  a <- array(1:4, c(2,2), list(c("foo", "bar"),c("baz", "qux")))
  b <- array(1:4, c(2,2), list(c("FOO", "BAR"),c("BAZ", "")))
  checkEquals(concatenate(a, b, along=2),
              array(c(1,2,3,4,1,2,3,4),
                    c(2, 4),
                    dimnames=list(c("foo", "bar"),
                         c("baz", "qux", "BAZ", ""))))
}

test.concatenate.some.colnames <- function() {
  #the column names behave like cbind, with the first encountered colnames winning.
  a <- array(1:4, c(2,2), list(c("foo", "bar"),c("baz", "qux")))
  b <- array(1:4, c(2,2), list(c("FOO", "BAR"),NULL))
  checkEquals(concatenate(b, a, along=1),
              array(c(1,2,1,2,3,4,3,4),
                    c(4, 2),
                    list(c("FOO", "BAR", "foo", "bar"), c("baz", "qux"))))
  #the first encountered dimnames refers to the entire dimnames array, not individual entries
  dimnames(b)[[2]] <- c("BAZ", "");
  checkEquals(concatenate(b, a, along=1),
              array(c(1,2,1,2,3,4,3,4),
                    c(4, 2),
                    list(c("FOO", "BAR", "foo", "bar"), c("BAZ", ""))));
}

test.concatenate.some.rownames <- function() {
  a <- array(1:4, c(2,2), list(c("foo", "bar"),c("baz", "qux")))
  b <- array(1:4, c(2,2), list(c("FOO", "BAR"),NULL))
  checkEquals(concatenate(a, b, along=1),
              array(c(1,2,1,2,3,4,3,4),
                    c(4, 2),
                    list(c("foo", "bar", "FOO", "BAR"), c("baz", "qux"))))
}

test.concatenate.3bind.dimnames <- function() {
  a <- array(1:8,
             c(2,2,2),
             list(c("foo", "bar"), c("baz", "qux"), c("quux", "corge")))
  b <- array(seq(10, 80, 10),
             c(2,2,2),
             list(c("grault", "garply"), c("waldo", "fred"), c("plugh", "xyzzy")))
  #
  checkEquals(concatenate(a, b, along=3),
              array(c(1:8,seq(10,80,10)),
                    c(2,2,4),
                    list(c("foo", "bar"),
                         c("baz", "qux"),
                         c("quux", "corge", "plugh", "xyzzy"))))
}
