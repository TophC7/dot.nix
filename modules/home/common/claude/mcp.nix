#
# Claude Code MCP (Model Context Protocol) servers configuration.
# Global MCP servers are defined here; project-specific servers go in .mcp.json
#
_: {
  # MCP servers can be configured here when needed.
  # Global servers apply to all projects; project-specific go in .mcp.json
  #
  # Example structure for future use:
  #
  # home.file.".claude.json" = {
  #   text = builtins.toJSON {
  #     mcpServers = {
  #       "server-name" = {
  #         command = "${pkgs.some-package}/bin/server";
  #         args = [ "--flag" ];
  #       };
  #     };
  #   };
  # };
}
