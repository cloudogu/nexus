{
  "name": "ces-default-cleanuppolicy",
  "notes": "{{ .Config.GetOrDefault "cleanup_policy/notes" "Default policy that is generated by the ces via a script on nexus startup"}}",
  "mode": "deletion",
  "format": "{{ .Config.GetOrDefault "cleanup_policy/policy_format" "maven2"}}",
  "criteria": {
    "regex": "{{ .Config.GetOrDefault "cleanup_policy/criteria/regex" ".*SNAPSHOT"}}",
    "criteriaReleaseType": "{{ .Config.GetOrDefault "cleanup_policy/criteria/release_type" "PRERELEASES"}}",
    "criteriaLastBlobUpdated": "{{ .Config.GetOrDefault "cleanup_policy/criteria/days_till_recognition_for_delete" "14"}}"
  }
}