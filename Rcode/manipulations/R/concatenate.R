concatenate <- function
###Concatenate multi-dimensional arrays along the given dimension, a
###generalization of cbind().  Arrays must have the same dimensions
###except gor the dimension along which the binding occurs. Attempts
###to preserve dimnames; if more than one argument provides names for
###a dimension, the earlier argument takes precedence.  Arrays may
###have different numbers of dimensions in which case they are taken
###to have length 1 in all training dimensions. Vectors without a dim
###attribute are taken to be column vectors.
(..., ###arguments to be bound
 along=N, ###the dimension along which arrays are to be
          ###bound. Defaults to the greatest number of dimensions
          ###among the arguments.
 fill=FALSE, ###if set to TRUE, binding unequally
             ###sized or mismatched arrays is permitted. NA will be
             ###used to fill out the parts of the array not covered.
 match.names=FALSE ###Attempt to arrange the data in
                   ###a way that matches dimnames between arguments
                   ###(ala smartbind.) When this is enabled, no slice
                   ###without a name will be bound to a slice with a
                   ###name.
 ) {

  arg.list = list(...)

  #save original dimensions and number of dimensions. Undimensioned
  #vectors are assumed to be "column vectors"
  dims <- lapply(arg.list, function(x) if (is.null(dim(x))) length(x) else dim(x))
  N <- sapply(c(0, dims), length)
  N <- max(N, along)

  #capture the dimnames in a 2d array(arg no. dimension). We convert
  #NULLs to NAs because is.na works elementwise and is.null does not.
  apply.dimnames <- FALSE
  dno = array(list(NA), c(N, length(arg.list)))
  for (i in 1:length(arg.list)) {
    dn <- dimnames(arg.list[[i]])
    if (!is.null(dn)) {
      apply.dimnames <- TRUE
      dn[sapply(dn,is.null)] <- NA;
      dno[1:length(dn), i] <- dn;
    }
  }
 
  #any unstated dimensions are assumed to be 1; one-pad the dimensions
  #here is the bug?
  arg.list <- mapply(function(arg, d) {
                       length(d) <- N;
                       d[is.na(d)] <- 1;
                       dim(arg) <- d;
                       arg
                     },
                     arg.list,
                     dims,
                     SIMPLIFY=FALSE)

  #useful to have a 2d array of the dimnames.
  dimarray <- do.call(rbind,lapply(dim, arg.list));
  #how to get a 2d array of the dimnames?
  
  if (match.names) {
    #we need to permute the contents of the array into its ultimate
    #order. There is a permutation for each dimension of each
    #argument.
    permutations = array(list(), c(length(arg.list), N));

    #determine the unique set of dimnames for each dimension; listed
    #in order of appearance.
    for (i in (1:N)[-along]) {
      dimnames.out[[i]] <- unique(do.call(c, dno[,i]))
    }
    
    #determine how many unnamed indices there are for each dimension in each argument...
    unused = 

                                        #apply the known dimnames to our input

                                        #build the output array.

                                        #now determine the size of the output array.
    
    sz <- lapply(length, dimnames.out)
    arg.list <- lappaly(simplify=FALSE, function(l) {
      #reorder each argument in the non-bound dimensions
      sout <- sapply(length, dimnames.out)
    })
    
  } else {
    dimnames.out <- vector("list", N);
    #the dimnames that wins is the first non-NA in every row.
    for (i in length(arg.list):1) {
      dimnames.out[!is.na(dno[,i])] <- dno[!is.na(dno[,i]),i]
    }
  }
  
  #Now deal with the dimnames in the concatenated dimension....
  if (!is.null(dimnames.out[along])) {
    nonames.args <- is.na(dno[along,])
    dno[along,nonames.args] <-
      lapply(arg.list[nonames.args],
             function(x)vector("character", dim(x)[along]))
    
    dimnames.out[[along]] <- do.call(c, dno[along,])
  }

  #the output dimension equals the max of the input dimensions and the concatenation...
  dimout <- do.call(pmax, c(lapply(arg.list, dim), list(rep(0,N))))

  if(fill) {
    stop("fill option not yet implemented")
  }

  #everything ought to have the same dimension otherwise
  if (any(sapply(arg.list, function(x) any(dim(x)[-along] != dimout[-along])))) {
    stop("arguments should have consistent dimensions")
  }


    
  #bring bound dimension to END
  permutation <-  c((1:N)[-along], along)
  arg.list <- lapply(arg.list, aperm, permutation)

  #straighten out other dimensions:
  arg.list <- lapply(arg.list, function(x)array(x, c(prod(dimout[-along]), dim(x)[N])))

  #desired output size:
  dimout[along] <- sum(sapply(arg.list, function(x)dim(x)[2]))
  
  #do cbind, reshape back and depermute
  bound <- array(do.call(cbind, arg.list), c(dimout[-along], dimout[along]))
  invperm <- permutation;
  invperm[permutation] <- (1:N)
  bound <- aperm(bound, invperm) #depermute

  #apply the dimnames.
  if(apply.dimnames) {
    dimnames(bound) <- dimnames.out
  }

  return(bound)
###The bound array.
}
