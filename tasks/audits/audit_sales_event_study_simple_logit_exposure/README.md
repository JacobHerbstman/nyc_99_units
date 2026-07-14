# Simple-Logit Sales Event Study Audit

This audit asks what the opportunity-site sales panel looks like when lots are ranked by the
reference simple-logit prediction score.

The score is fit on observed 50+ unit HDB New Building filings from 2010-2020, with the binary
outcome `classa_prop >= 100`. The fitted score is then applied to frozen opportunity lots in the
lot-quarter sales panel. The audit compares top-versus-bottom terciles and quartiles of the score.

The task reports both quarterly and semi-annual versions. In the semi-annual version, sale incidence
is an indicator for any primary private ACRIS sale in the lot-half-year. Conditional price uses total
complete primary allocated sale price in the lot-half-year divided by allowed residential square feet;
the summary table reports how often a half-year contains multiple sale quarters.

This is exploratory outcome work. It should not be treated as a production research-design object
until the prediction score, opportunity universe, and private-market sale screen are locked down.
