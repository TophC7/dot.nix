# JSON Type Definition schemas for agent reports. Agent frontmatter names one
# under `[output]`; the remaining `[output]` keys are its arguments.
{
  review =
    { scope, ... }:
    {
      properties.coverage_summary.type = "string";
      optionalProperties.findings.elements = {
        properties = {
          severity.enum = [
            "Blocking"
            "Required"
            "Suggestion"
          ];
          scope.enum = [ scope ];
          location.type = "string";
          problem.type = "string";
          evidence.type = "string";
          fix_direction.type = "string";
        };
      };
    };

  decomplect = _: {
    properties = {
      coverage.type = "string";
      current_model.type = "string";
    };
    optionalProperties = {
      proposals.elements = {
        properties = {
          root_cause.type = "string";
          evidence.type = "string";
          change.type = "string";
          consumers.type = "string";
          net_effect.type = "string";
          verification.type = "string";
          confidence.enum = [
            "High"
            "Medium"
            "Low"
          ];
        };
        optionalProperties.decision.type = "string";
      };
      retain.elements.type = "string";
    };
  };
}
