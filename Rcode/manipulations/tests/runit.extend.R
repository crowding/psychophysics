test.extend <- function() {
  a <- array(1:4, c(2,2))
  checkEquals(extend(a, c(3,2)), array(c(1,2,NA,3,4,NA), c(3,2)))
  checkEquals(extend(a, c(2,3)), array(c(1,2,3,4,NA,NA), c(2,3)))
}

test.extend.with.dimnames <- function() {
  a <- array(1:4, c(2,2), dimnames=list(c("foo", "bar"), c("baz", "qux")))
  checkEquals(extend(a, c(3,2)),
              array(c(1,2,NA,3,4,NA), c(3,2),
                    dimnames=list(c("foo", "bar", NA),c("baz", "qux"))))
  checkEquals(extend(a, c(2,3)),
              array(c(1,2,3,4,NA,NA), c(2,3),
                    dimnames=list(c("foo", "bar"), c("baz", "qux", NA))))
}

## test.extend.new.dimension <- function() {
##   a <- array(1:4, c(2,2))
##   checkEquals(extend(a, c(2,2,2)), array(c(1,2,3,4,NA,NA,NA,NA), c(2,2,2)))
## }

test.truncate <- function() {
  a <- array(1:4, c(2,2))
  checkEquals(extend(a, c(2,1)), array(c(1,2), c(2,1)))
}

