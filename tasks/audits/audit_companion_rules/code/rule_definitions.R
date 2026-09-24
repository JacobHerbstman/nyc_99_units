# Companion rules shared by the evaluation and the parent simulation.
# Which identity field must match, and how close the filings are.
identity_rules <- list(
  business = quote(same_business),
  person = quote(same_person),
  business_or_person = quote(same_business | same_person),
  applicant = quote(same_applicant),
  business_and_applicant = quote(same_business & same_applicant),
  person_and_applicant = quote(same_person & same_applicant),
  business_or_person_and_applicant = quote((same_business | same_person) & same_applicant)
)
space_rules <- c(same_block = NA, m50 = 50, m100 = 100, m150 = 150, m150_or_block = 150, m250 = 250)
rules <- expand_grid(identity_rule = names(identity_rules), space_rule = names(space_rules),
  max_days = c(90L, 365L))

rule_links <- function(data, identity_rule, space_rule, max_days) {
  keep <- eval(identity_rules[[identity_rule]], data) & data$days_apart <= max_days
  near <- switch(space_rule,
    same_block = data$same_block,
    m150_or_block = (data$same_block & data$distance_metres <= 200) | data$distance_metres <= 150,
    data$distance_metres <= space_rules[[space_rule]])
  keep & near
}
