box::use(
  XML[newXMLDoc, newXMLNode, addChildren, saveXML],
  readr[read_csv, cols],
)

make_nl_XML <- function(input_list){
  
 experimentXML <- newXMLDoc()

  experiment <- newXMLNode(
    "experiment",
    attrs = list(
      name = "Exp1",
      repetitions = "1",
      runMetricsEveryStep = "true"
    )
  ) 
  experiment <- experiment |>
    addChildren(
      newXMLNode(
        "setup",
        "setup",
        parent = experiment
      )
    ) |>
    addChildren(
      newXMLNode(
        "go",
        "go",
        parent = experiment
      )
    ) |>
    addChildren(
      newXMLNode(
        "timeLimit",
        attrs = c(steps = input_list$sim_days),
        parent = experiment
      )
    )
  
  for (i in seq_along(input_list$metric)) {
    experiment <- experiment |>
      addChildren(
        newXMLNode(
          "metric",
          input_list$metrics[[i]],
          parent = experiment
        )
      )
  }
  
  variables_names <- input_list$variables |>
    names()
  
  for (i in seq_along(input_list$variables)) {
    experiment <- experiment |>
      addChildren(
        newXMLNode(
          "enumeratedValueSet",
          newXMLNode(
            "value",
            attrs = c(value = input_list$variables[[i]])
          ),
          attrs = c(variable = variables_names[i]),
          parent = experiment
        )
      )
  }
  
  experiments <- newXMLNode(
    "experiments",
    experiment,
    doc = experimentXML
  )
  
  return(experiments)
}

#' @export
run_simulation <- function(
    netlogo_jar_path,
    model_path,
    output_path,
    input_list,
    xml_path = NULL,
    memory = 2048,
    threads = 1
) {
  
  if (is.null(xml_path)) {
    xml_path <- paste0(tempfile(pattern = "netlogo_xml_"), ".xml")
  }
  
  print(input_list)
  
  simulation_xml <- make_nl_XML(input_list)

  saveXML(
    simulation_xml,
    file = xml_path
  )

  system_cmd <- paste0(
    'java ',
    ' -Xmx', memory, 'm -Dfile.encoding=UTF-8',
    ' -classpath "', netlogo_jar_path, '"',#netlogo_home,'/app/netlogo-',netlogo_version,'.jar"',
    ' org.nlogo.headless.Main',
    ' --model "', model_path, '"',
    ' --setup-file "', xml_path, '"',
    ' --experiment Exp1',
    ' --table "', output_path, '"',
    ' --threads ', threads
  )
  print(system_cmd)
  system(system_cmd)
  
  results <- read_csv(
    output_path,
    skip = 6,
    col_types = cols()
  )
  
  return(results)
}
