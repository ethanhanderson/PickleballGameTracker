# Pickleball Game Tracker: agent setup

## MCP servers (project config in `.mcp.json` and `.cursor/mcp.json`)
- `xcode-tools`: Xcode's built-in MCP bridge (`xcrun mcpbridge`). Open the project in Xcode first. Use it to build, run tests, read build logs and render previews.
- `supabase`: hosted server at `https://mcp.supabase.com/mcp`, scoped to project `upociuofzihseweiygfv`. It signs in with your Supabase account in the browser. Do not add an access token or API key to any config file.

## First-time login
1. Claude Code: run `claude /mcp`, select `supabase`, choose Authenticate.
2. Cursor: open Settings > MCP, select `supabase`, choose Connect. Or run `agent mcp login supabase`.
3. Choose the Supabase organization that owns project `upociuofzihseweiygfv`.

## Skills
Supabase skills come from `supabase/agent-skills` and are pinned in `skills-lock.json`. Run `npx skills update -p -y` to update them.

## Rules
- Never commit secrets, `.env` files or `*.local.json` files.
- Use the Supabase publishable key in app config only. Never use a service-role key in an app.
