aapc<-function(ogg, parm, exp.it=FALSE, conf.level=0.95, wrong.se=TRUE){
      blockdiag <- function(...) {
        args <- list(...)
        nc <- sapply(args,ncol)
        cumnc <- cumsum(nc)
        ##  nr <- sapply(args,nrow)
        ## NR <- sum(nr)
        NC <- sum(nc)
        rowfun <- function(m,zbefore,zafter) {
          cbind(matrix(0,ncol=zbefore,nrow=nrow(m)),m,
                matrix(0,ncol=zafter,nrow=nrow(m)))
        }
        ret <- rowfun(args[[1]],0,NC-ncol(args[[1]]))
        for (i in 2:length(args)) {
          ret <- rbind(ret,rowfun(args[[i]],cumnc[i-1],NC-cumnc[i]))
        }
        ret
      }
#PER UNA VARIABILE SEGMENTED
        if(missing(parm)) {
          nomeZ<- ogg$nameUV[[3]]
#          if(length(rev.sgn)==1) rev.sgn<-rep(rev.sgn,length(nomeZ))
          } else {
                if(! all(parm %in% ogg$nameUV[[3]])) {stop("invalid parm")}
                  else {nomeZ<-parm}
                  }


#for(i in 1:length(nomeZ)) {
	term<-nomeZ[1]
    nomi.psi<- grep(paste("\\.",term,sep=""), ogg$nameUV$V, value=TRUE)
	
	nomi.slope<- grep(paste("\\.",term,sep=""), ogg$nameUV$U,value=TRUE)
	null.left<-TRUE
	if(term %in% names(ogg$coefficients)) {
		nomi.slope<-c(term, nomi.slope)
		null.left<-FALSE
		}
	a<- min(ogg$rangeZ[,parm])# min(x)-1 #se discreto
  b<- max(ogg$rangeZ[,parm])
  est.slope <- slope(ogg, parm)[[1]][,1]
  est.psi <- ogg$psi[nomi.psi,2]
  est.w<- diff(c(a,est.psi,b))/(b-a) #drop(B%*%c(a,est.psi,b))
  k<- length(est.psi)#n.changepoints
#browser()
#  if(null.left) {
#                est.w<-est.w[-1]
#                est.slope<-est.slope[-1]
#                k<-k-1
#                }
  
  
  A<-matrix(0,k+1,k+1)
  A[row(A)>=col(A)]<-1
  B<-diff(diag(k+2),diff=1)/(b-a)
  mu<-drop(crossprod(est.w,est.slope))
  xsi<-c(crossprod(est.w,A),crossprod(est.slope,B))
	v.delta<-vcov(ogg)[nomi.slope,nomi.slope] 
# if(null.left) v.delta<-rbind(0,cbind(0,v.delta))
	
	#v.delta<-vcov(ogg)[2:4,2:4] #questa e' la var cov della left slope e le altre diffSlope
  #v.psi<-vcov(ogg)[5:6,5:6] #questa e' la var-cov dei psi
  v.psi<-as.matrix(vcov(ogg)[nomi.psi,nomi.psi])

	VC<-vcov(ogg)[nomi.psi, nomi.slope]
	VV<-blockdiag(v.delta,diag(1)*0,v.psi,diag(1)*0)
	id.cov1<- 1:length(est.slope)
	id.cov2<- seq.int((length(est.slope)+2), length.out=length(est.psi))
	
  if(null.left) {
                VC<-cbind(0,VC) #column relevant to the "x"	term (missing)
                VV<- rbind(0,cbind(0,VV))
                }
	
	VV[id.cov2,id.cov1]<-VC
  VV[id.cov1,id.cov2]<-t(VC)
	
	#VV[5:6,1:3]<-vcov(os)[5:6,2:4]
  #VV[1:3,5:6]<-vcov(os)[2:4,5:6]


  se.mu<-sqrt(drop(xsi%*%VV%*%xsi))
	z<-abs(qnorm((1-conf.level)/2))
	r<-c(Est=mu, St.Err=se.mu, mu+c(-z,z)*se.mu)
	cin <- paste("CI", "(", conf.level * 100, "%", ")", c(".l", ".u"), sep = "")
	names(r)<-c("Est.","St.Err",cin)
  if(wrong.se){
        if(null.left) v.delta<-rbind(0,cbind(0, v.delta))
        se.mu.wrong<- sqrt(drop(t(est.w)%*%A%*%v.delta%*%t(A)%*%est.w))
	      attr(r,"wrong.se")<- se.mu.wrong
        }
  if(exp.it) r<- exp(r[-2])-1
	r
}
    

    
    
    





