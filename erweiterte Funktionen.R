#'lda_getTopTexts
#'
#'Generiert die Top-Texte (n=100) einer LDA und speichert sie in einem entsprechenden Ordner auf dem Rechner ab. F?hrt die tosca-Funktionen "topTexts()" und "showTexts()" durch
#'
#'@param corpus Ausgangskorpus als meta-Datei. Sollte im Vorhinein um Duplikate bereinigt werden
#'@param ldaResult Objekt, das die tosca-Funktion "LDAgen()" generiert
#'@param ldaID IDs von Texten, die beruecksichtigt werdeb sollen. Default: Alle Texte
#'@param nTopTexts Menge an TopTexts, die generiert wird
#'@param file Dateiname
#'
lda_getTopTexts = function(corpus, ldaResult, ldaID, nTopTexts=50, file="topTexts"){
  
  corp=T
  if(!is.textmeta(corpus)){corpus = as.textmeta(corpus); corp=FALSE}
  if(missing(ldaID)){ldaID = names(corpus$text); warning("Missing ldaID. IDs of the corpus text are used as proxies.\nTrue IDs may differ!\nPlease check the generated top texts.")}
  if(missing(corpus)|missing(ldaResult)) stop("Insert correct arguments for corpus and ldaResult")
  if(!require("writexl", character.only = T, quietly = T)){
    install = as.logical(as.numeric(readline("Package 'writexl' is not installed but required. Shall it be installed now? (NO: 0, YES: 1)  ")))
    if(install) install.packages("writexl") else break
  }
  
  require(writexl, quietly = T)
  require(tosca, quietly = T)
  
  #generate data frame of topTexts
  tt = topTexts(ldaResult, ldaID, nTopTexts)
  tt = showTexts(corpus, tt)
  
  #add share of most prominent topic per tt to data frame
  docs_per_topic = ldaResult$document_sums/rowSums(ldaResult$document_sums)
  docs_per_topic = apply(docs_per_topic, 2, function(x) x/sum(x))
  proms = apply(docs_per_topic, 1, function(x) round(sort(x,decreasing = T)[1:nTopTexts],2))
  for(i in 1:length(tt)){tt[[i]][,"topic_relevance"] = proms[,i]; tt[[i]] = tt[[i]][,c(1,2,5,3,4)]}
  
  #add resource to data frame
  if("resource" %in% names(corpus$meta)){
    tt = lapply(tt, function(x){
      x[,"source"] = corpus$meta$resource[match(x[,"id"],corpus$meta$id)]
      x[,c(1,2,3,6,4,5)]})}
  if(!corp) tt = lapply(tt, function(topic) topic[,c(1,3,5)])
  
  # save locally
  if(!is.null(file)) writexl::write_xlsx(tt, paste0(sub(".xlsx","",file),".xlsx"))
  
  invisible(tt)
}


#'lda_getTopWords
#'
#'Generiert ein Excel-Sheet mit den topwords einer LDA
#'
#'@param ldaResult Objekt, das die tosca-Funktion "LDAgen()" generiert
#'@param numWords Anzahl der topwords pro Topic
#'@param file Dateiname, unter dem das Excel-Sheet gespeichert werden soll
#'
lda_getTopWords = function(ldaResult, numWords=50, file="topwords"){
  
  if(!require("writexl", character.only = T, quietly = T)){
    install = as.logical(as.numeric(readline("Package 'writexl' is not installed but required. Shall it be installed now? (NO: 0, YES: 1)  ")))
    if(install) install.packages("writexl") else break
  }
  require(tosca, quietly = T)
  require(writexl, quietly = T)
  
  topwords = topWords(ldaResult$topics, numWords)
  rel = round(rowSums(ldaResult$topics)/sum(ldaResult$topics),3)
  topwords = as.data.frame(rbind(rel,topwords))
  colnames(topwords) = paste("Topic",1:ncol(topwords))
  rownames(topwords) = NULL
  
  # save locally
  if(!is.null(file)) writexl::write_xlsx(topwords, paste0(sub(".xlsx","",file),".xlsx"))
  
  invisible(topwords)
}


#'topTextsPerUnit
#'
#'Errechnet die TopTexts pro Monat/Bimonth/Quartal/Halbjahr/Jahr basierend auf einem tosca-LDA-Objekt und speichert sie (falls gew?nscht) lokal
#'
#'@param corpus Textkorpus
#'@param ldaResult Objekt, das die tosca-Funktion "LDAgen()" generiert
#'@param unit month, bimonth. quarter, halfyear oder year
#'@param nTopTexts Anzahl der toptexte, die pro Topic und Periode generiert werden soll
#'@param tnames (optional) desired topic names
#'@param foldername name of folder in which the top texts are saved in. If NULL (default), texts are not saved locally
#'
topTextsPerUnit = function(corpus, ldaResult, unit="quarter", nTopTexts=20, tnames=NULL, foldername=NULL, s.date=min(corpus$meta$date, na.rm=T), e.date=max(corpus$meta$date, na.rm=T)){
  
  if(missing(corpus)|missing(ldaResult)|!robot::is.textmeta(corpus)) stop("Insert correct arguments for corpus, ldaResult and topic")
  require(tosca, quietly = T)
  require(lubridate, quietly = T)
  
  K = nrow(ldaResult$topics)
  ldaID = names(corpus$text)
  doc = ldaResult$document_sums
  colnames(doc)=as.character(corpus$meta$date[match(ldaID,corpus$meta$id)])
  if(is.null(tnames)) tnames = paste0("Topic",1:K,".",topWords(ldaResult$topics))
  if(!is.null(foldername)) dir.create(foldername)
  
  q = c(month=1,months=1,bimonth=2,bimonths=2,quarter=3,quarters=3,year=12,years=12)[unit]
  chunks = seq.Date(s.date, e.date, unit)
  
  progress.initialize(chunks)
  out = lapply(chunks, function(chunk){
    
    chunk = as.Date(chunk)
    currSpan = chunk < as.Date(colnames(doc)) & as.Date(colnames(doc)) < chunk+months(q)
    temp = doc[, currSpan]
    docs_per_topic = apply(temp, 2, function(x) x/sum(x))
    
    temp = apply(docs_per_topic, 1, function(x){
      proms = order(x,decreasing = T)[1:nTopTexts]
      ids = ldaID[currSpan][proms]
      ids = ids[!is.na(ids)]
      if(!is.null(foldername)){
        texts = showTexts(corpus, ids)
        texts[,"topic_relevance"] = round(sort(x,decreasing = T)[1:nTopTexts],2)
        if("resource" %in% names(corpus$meta)){
          texts[,"source"] = corpus$meta$resource[match(texts[,"id"],corpus$meta$id)]
          texts = texts[,c(1,2,6,5,3,4)]} else texts = texts[,c(1,2,5,3,4)]
        texts
      }else ids
    })
    names(temp) = tnames
    
    # save locally
    if(!is.null(foldername)) writexl::write_xlsx(temp, paste0(foldername,"/",chunk,".xlsx"))
    
    progress.indicate()
    temp
  })
  if(is.null(foldername)){
    out = lapply(1:K, function(k){
      sapply(1:length(chunks), function(t) out[[t]][,k])
    })
    out = lapply(out, function(x){colnames(x)=as.character(chunks); x})
    names(out) = tnames
  }
  
  invisible(out)
}

#'topWordsPerUnit
#'
#'Erzeugt ein Objekt, dass die Topwords pro Monat/Bimonth/Quartal/Halbjahr/Jahr ausgibt
#'
#'@param corpus Textkorpus
#'@param ldaResult Objekt, das die tosca-Funktion "LDAgen()" generiert
#'@param docs Objekt, das die Funktion LDAprep() generiert
#'@param unit month, bimonth. quarter, halfyear oder year
#'@param numWords Anzahl der topwords pro Topic
#'@param tnames (optional) desired topic names
#'@param values Wenn TRUE, werden zu den topwords selbst auch die zugehoerigen Werte ausgegeben
#'@param s.date optional: Start-Datum, Wenn nur ein Teil der TopTexte von Interesse ist
#'@param e.date optional: End-Datum, Wenn nur ein Teil der TopTexte von Interesse ist
#'@param saveRAW Wenn TRUE werden die in der Analyse erzeugten Zwischenergebnisse ins Environment geladen
#'@param file Dateiname, unter dem das Excel-Sheet gespeichert werden soll
#'
topWordsPerUnit = function(corpus, ldaResult, docs, unit="quarter", numWords=50, tnames=NULL, values=T, s.date=NULL, e.date=NULL, saveRAW=F, file=NULL){
  
  if(missing(corpus)|missing(ldaResult)|missing(docs)) stop("Insert arguments for corpus, ldaResult, and docs")
  
  if(!is.null(file) && !require("writexl", character.only = T, quietly = T)){
    install = as.logical(as.numeric(readline("Package 'writexl' is not installed but required. Shall it be installed now? (NO: 0, YES: 1)  ")))
    if(install) install.packages("writexl") else break
  }
  library(lubridate)
  library(tosca)
  require(writexl, quietly = T)
  
  K = nrow(ldaResult$topics)
  assignments = ldaResult$assignments
  vocab = colnames(ldaResult$topics)
  if(is.null(tnames)) tnames = paste0("Topic",1:K,".",topWords(ldaResult$topics)) else tnames = tnames
  
  date_chunks = lubridate::floor_date(corpus$meta$date[match(names(docs), corpus$meta$id)], unit)
  chunks = unique(date_chunks); min = chunks[1]; max = tail(chunks,1)
  if(!is.null(s.date)) min = floor_date(as.Date(s.date),unit); if(!is.null(e.date)) max = floor_date(as.Date(e.date),unit)
  chunks = chunks[chunks >= min & chunks <= max]
  
  topicsq = lapply(chunks, function(x){
    tmp = table(factor(unlist(assignments[date_chunks == x])+1, levels = 1:K),
                factor(unlist(lapply(docs[date_chunks == x], function(y) y[1,]))+1, levels = seq(length(vocab))))
    tmp = matrix(as.integer(tmp), nrow = K)
    colnames(tmp) = vocab
    tmp
  })
  if(saveRAW) names(topicsq)=chunks; ttm <<- topicsq
  topwordsq = lapply(topicsq, topWords, numWords = numWords, values = T)
  names(topwordsq)=chunks
  
  out = lapply(1:K, function(k) sapply(seq(topwordsq), function(t) topwordsq[[t]][[1]][,k]))
  out = lapply(out, function(x){ colnames(x)=as.character(chunks); x})
  names(out) = tnames
  if(values) out = list(words=out, vals=lapply(1:K, function(k) sapply(seq(topwordsq), function(t) topwordsq[[t]][[1]][,k])))
  
  if(!is.null(file)){
    
    # save locally
    if(values) words=out[[1]] else words=out
    words = lapply(words, as.data.frame)
    writexl::write_xlsx(words, paste0(sub(".xlsx","",file),".xlsx"))
    
  }
  
  invisible(out)
}



# -------------------------------------------------------------------------
# helper funcs
# -------------------------------------------------------------------------


#'as.textmeta
#'
#'transforms a named vector or a named list to a tosca::textmeta-file
#'
#'@param named_object Textfile to convert
#'@return textmeta-Objekt
#'@export
#'
as.textmeta = function(named_object){
  if(is.null(names(named_object))) names(named_object) = paste0("text_",seq(length(named_object)))
  
  if(!is.list(named_object)) named_object = as.list(named_object)
  return(
    tosca::textmeta(text=named_object,
                    meta=data.frame(id=names(named_object),
                                    date="",
                                    title="",
                                    fake="")
    )
  )
}


#'is.textmeta
#'
#'Testet, ob ein Objekt ein Textmeta-Objekt (im Sinne von tosca) ist
#'
#'@param obj Das Objekt, das getestet werden soll
#'@return TRUE oder FALSE
#'@examples is.textmeta(HB)
#'@export
#'
is.textmeta = function(obj){
  is.list(obj) & all(c("meta","text") %in% names(obj))
}


