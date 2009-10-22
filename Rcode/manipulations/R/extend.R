extend <- function
###extend (or truncate) a multidimensional array by adding NA entries
###at the end or each dimension (or truncate by deleting.) The number
###of dimensions of a must equal the length of d.
(a, ###the array to resize
 d) ###the dimension to resize it to. the length of d must equal the length of dim(a).
{
  ad <- dim(a);
  length(ad) <- length(d) <- max(length(ad), length(d));
  ad[is.na(ad)] <- 1;
  d[is.na(d)] <- 1;
  ##this would deal with different numbers of dimensions between A and
  ##B, but it screws up dimnames, so is diabled.
  ##dim(a) <- ad;
  index <- mapply(
                  function(old, new) c(1:min(old, new), array(NA, max(0, new - old))),
                  ad, d, SIMPLIFY=FALSE)
  do.call("[", c(list(a), index, drop=FALSE))
}

