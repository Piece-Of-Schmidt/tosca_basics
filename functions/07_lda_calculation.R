# decompose LDA result, so that a document_topic_matrix is grouped by another meta variable
decompose_lda = function(document_topic_matrix, lookup_dict, select=1:nrow(document_topic_matrix), unit="month", tnames=paste0("topic", select), plot=F, out="melt"){
  
  # LOOKUP-DICT: create floor_dates
  colnames(lookup_dict) = c("id", "date", "group")
  lookup_dict$date = lubridate::floor_date(lookup_dict$date, unit=unit)
  
  # DTM: create rownames & colnames and restrict DTM to selected topics
  colnames(document_topic_matrix) = lookup_dict$id
  document_topic_matrix = document_topic_matrix[select, , drop=F]
  rownames(document_topic_matrix) = tnames
  
  # DTM: create long format
  long_format = reshape2::melt(document_topic_matrix)
  colnames(long_format) = c("topic", "id", "count")
  
  # DTM: merge with LOOKUP-DICT
  merged_data = long_format %>%
    left_join(lookup_dict, by = "id") %>%
    group_by(date, group, topic) %>%
    summarise(doc_count = sum(count))
  
  # FINAL: create plot
  if(plot){
    print(ggplot2::ggplot(merged_data, aes(x = date, y = doc_count, color = group)) +
            geom_smooth(se=F, span=0.1) +
            facet_wrap(~ topic) +
            theme_minimal() +
            labs(x = "Monat", y = "Anzahl Dokumente", color = "Quelle"))
  }
  
  result = if(out == "melt") merged_data else dcast(merged_data, date + group ~ topic, value.var = "doc_count")
  
  return(result)
}