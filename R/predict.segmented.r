predict.segmented <-function(object, newdata, .coef=NULL, ...){
#rev: 30/10/2013: it seems to work correctly, even with the minus variable (null right slope..)
#rev: 14/4/2014 now it works like predict.lm/glm
#BUT problems if type="terms" (in realta' funziona, il problema e' che
#     restituisce una colonna per "x", "U.x", "psi.x".. (Eventualmente si dovrebbero sommare..)
#if(!is.null(object$orig.call$offset)) stop("predict.segmented can not handle argument 'offset'. Include it in formula!")

  estcoef<- if(is.null(.coef)) coef(object) else .coef
  
  vS<-function(obj){
    X<-model.matrix(obj)
    nomiZ<- obj$nameUV$Z
    nomiV<- obj$nameUV$V
    for(i in 1:length(nomiZ)){
      nomeZ<-nomiZ[i]
      nomeV<-nomiV[i]
      Z<-X[,nomeZ]
      est.psi<- obj$psi[nomeV,"Est."]
      se.psi<- obj$psi[nomeV,"St.Err"]
      X[,nomeV]<-X[,nomeV]*pnorm((Z-est.psi)/se.psi)
    }
    s2<-summary.lm(obj)$sigma^2
    s2*solve(crossprod(X))
  }
  
#se gli passo isV=TRUE cosa cambia in predict??  
  dummy.matrix<-function(x.values, x.name, obj.seg, psi.est=TRUE, isV=FALSE){ 
    #given the segmented fit 'obj.seg' and a segmented variable x.name with corresponding values x.values,
    #this function simply returns a matrix with columns (x, (x-psi)_+, -b*I(x>psi))
    #or  ((x-psi)_+, -b*I(x>psi)) if obj.seg does not include the coef for the linear "x"
        f.U<-function(nomiU, term=NULL){
        #trasforma i nomi dei coeff U (o V) nei nomi delle variabili corrispondenti
        #and if 'term' is provided (i.e. it differs from NULL) the index of nomiU matching term are returned
            k<-length(nomiU)
            nomiUsenzaU<-strsplit(nomiU, "\\.")
            nomiU.ok<-vector(length=k)
            for(i in 1:k){
                nomi.i<-nomiUsenzaU[[i]][-1]
                if(length(nomi.i)>1) nomi.i<-paste(nomi.i,collapse=".")
                nomiU.ok[i]<-nomi.i
                }
            if(!is.null(term)) nomiU.ok<-(1:k)[nomiU.ok%in%term]
            return(nomiU.ok)
            }
        if(length(isV)==1) isV<-c(FALSE,isV)
        n<-length(x.values)
        #le seguenti righe selezionavano (ERRONEAMENTE) sia "U1.x" sia "U1.neg.x" (se "x" e "neg.x" erano segmented covariates)
        #nameU<- grep(paste("\\.",x.name,"$", sep=""), obj.seg$nameUV$U, value = TRUE)
        #nameV<- grep(paste("\\.",x.name,"$", sep=""), obj.seg$nameUV$V, value = TRUE)
        nameU<-obj.seg$nameUV$U[f.U(obj.seg$nameUV$U,x.name)]
        nameV<-obj.seg$nameUV$V[f.U(obj.seg$nameUV$V,x.name)]

        diffSlope<-estcoef[nameU]
        est.psi<-obj.seg$psi[nameV,"Est."]
        se.psi<-obj.seg$psi[nameV, "St.Err"]
        k<-length(est.psi)
        PSI <- matrix(rep(est.psi, rep(n, k)), ncol = k)
        SE.PSI <- matrix(rep(se.psi, rep(n, k)), ncol = k)
        newZ<-matrix(x.values, nrow=n,ncol=k, byrow = FALSE)
        
        
        dummy1<-if(isV[1]) (newZ-PSI)*pnorm((newZ-PSI)/SE.PSI) else  (newZ-PSI)*(newZ>PSI) #pmax(newZ-PSI,0)
        
        if(psi.est){
          V<-if(isV[2]) -pnorm((newZ-PSI)/SE.PSI) else -(newZ>PSI) #ifelse(newZ>PSI,-1,0)
          dummy2<- if(k==1) V*diffSlope  else V%*%diag(diffSlope) #t(diffSlope*t(-I(newZ>PSI)))
          newd<-cbind(x.values,dummy1,dummy2)
          colnames(newd)<-c(x.name,nameU, nameV)
          } else {
          newd<-cbind(x.values,dummy1)
          colnames(newd)<-c(x.name,nameU)
          }
        if(!x.name%in%names(coef(obj.seg))) newd<-newd[,-1,drop=FALSE]
        #aggiungi (eventualmente) le colonne relative ai psi noti
        all.psi<-obj.seg$indexU[[x.name]]
        if(length(all.psi)!=k){
          nomi.psi.noti<-setdiff(names(all.psi),nameU)
          psi.noti<-setdiff(all.psi, est.psi)
          PSI.noti <- matrix(rep(psi.noti, rep(n, length(psi.noti))), ncol = length(psi.noti))
          nomi<-c(colnames(newd),nomi.psi.noti)
          newd<-cbind(newd, (newZ-PSI.noti)*(newZ>PSI.noti))
          colnames(newd)<-nomi
        }
        return(newd)
  }
  #--------------
  #--------------------------------------------------------------
  if(missing(newdata)){
    newdata <- model.frame(object)
  } else {
  #devi trasformare la variabili segmented attraverso dummy.matrix()
  nameU<-object$nameUV$U
  nameV<-object$nameUV$V
  nameZ<-object$nameUV$Z
  n<-nrow(newdata)
  r<-NULL
  for(i in 1:length(nameZ)){
      x.values<-newdata[[nameZ[i]]]
      DM<-dummy.matrix(x.values, nameZ[i], object)
      r[[i]]<-DM
      }  
  newd.ok<-data.frame(matrix(unlist(r), nrow=n, byrow = FALSE))
  names(newd.ok)<- unlist(sapply(r, colnames))
  idZ<-match(nameZ, names( newdata))
  newdata<-cbind(newdata[,-idZ, drop=FALSE], newd.ok) #  newdata<-subset(newdata, select=-idZ)
  #newdata<-cbind(newdata, newd.ok) #e' una ripetizione (refuso?) comunque controlla
  }
  if(class(object)[1]=="segmented") class(object)<-class(object)[-1]
  if(class(object)[1]=="lme"){
    object$call<- object$orig.call
    object$call$fixed <- update.formula(object$call$fixed,
      paste(".~.+", paste(c(object$nameUV$U, object$nameUV$V),collapse = "+")))
  }
  f<-predict(object, newdata=newdata, ...)
  #f<-if(inherits(object, what = "glm", which = FALSE)) predict.glm(object, newdata=newd.ok, ...) else predict.lm(object, newdata=newd.ok, ...)
  return(f)
#sommare se "terms"?
  }  
  
  
  
  
