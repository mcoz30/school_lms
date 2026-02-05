#!/usr/bin/env python3
# Read the original file
with open('index (7).html', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Find and replace lines
new_lines = []
skip_until = None
in_script_section = False

for i, line in enumerate(lines):
    # Start of script section
    if '<script type="module">' in line:
        in_script_section = True
        new_lines.append(line)
        # Add Turso import instead of Supabase
        new_lines.append("import { createClient } from 'https://cdn.jsdelivr.net/npm/@libsql/client-web@0.4.0/+esm';\n")
        new_lines.append("\n")
        new_lines.append("// --- TURSO CONFIGURATION ---\n")
        new_lines.append("const tursoUrl = 'libsql://schoollms-mcoz30.aws-ap-south-1.turso.io';\n")
        new_lines.append("const tursoToken = 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9.eyJhIjoicnciLCJpYXQiOjE3NzAyNTM1NjQsImlkIjoiMmE2YjA5ODMtZTgwNy00OTU4LWE5YmUtZjJhMTc3ZTNmMWEzIiwicmlkIjoiNGVkMGZmZjAtMzRkNS00YzBhLTliMzMtMmRiYTgxMWUwZjE3In0.eM21FQNmO5djrGaVUptwVZjkixTjmxOCc1kbBmhI5R2khoz_Y-b0qMsQ2efymR0hR-4vUDf8VCPp8MD0jQC-AA';\n")
        new_lines.append("\n")
        new_lines.append("const turso = createClient({\n")
        new_lines.append("    url: tursoUrl,\n")
        new_lines.append("    authToken: tursoToken,\n")
        new_lines.append("});\n")
        new_lines.append("\n")
        # Skip Supabase lines
        skip_until = '// --- DATA STORE ---'
        continue
    
    # Skip lines until we find the marker
    if skip_until:
        if skip_until in line:
            skip_until = None
            new_lines.append(line)
        continue
    
    # Remove supabaseUser from variable declaration
    if 'supabaseUser' in line and '=' in line:
        # Modify the line to remove supabaseUser
        line = line.replace(', supabaseUser = null', '')
        new_lines.append(line)
        continue
    
    # Replace SUPABASE SYNC section
    if '// --- SUPABASE SYNC ---' in line:
        # Add Turso sync functions
        new_lines.append("// --- TURSO SYNC ---\n")
        new_lines.append("async function initTurso() {\n")
        new_lines.append("    try {\n")
        new_lines.append("        // Create table if not exists\n")
        new_lines.append("        await turso.execute(`\n")
        new_lines.append("            CREATE TABLE IF NOT EXISTS app_data (\n")
        new_lines.append("                id TEXT PRIMARY KEY,\n")
        new_lines.append("                data TEXT,\n")
        new_lines.append("                updated_at TEXT\n")
        new_lines.append("            )\n")
        new_lines.append("        `);\n")
        new_lines.append("\n")
        new_lines.append("        // Try to load data from Turso\n")
        new_lines.append("        const result = await turso.execute({\n")
        new_lines.append("            sql: 'SELECT data FROM app_data WHERE id = ?',\n")
        new_lines.append("            args: ['master_record']\n")
        new_lines.append("        });\n")
        new_lines.append("\n")
        new_lines.append("        if (result.rows.length > 0 && result.rows[0].data) {\n")
        new_lines.append("            const savedData = JSON.parse(result.rows[0].data);\n")
        new_lines.append("            db = savedData;\n")
        new_lines.append("            ['activities','activitySubmissions','modules','exams','examSubmissions','globalEvents'].forEach(k=>{\n")
        new_lines.append("                if(!db[k]) db[k] = (k==='activitySubmissions'||k==='examSubmissions') ? {} : [];\n")
        new_lines.append("            });\n")
        new_lines.append("            if(!db.theme) db.theme = defaultData.theme;\n")
        new_lines.append("        } else {\n")
        new_lines.append("            // Initialize with default data\n")
        new_lines.append("            console.log(&quot;Initializing with default data&quot;);\n")
        new_lines.append("            await saveDB();\n")
        new_lines.append("        }\n")
        new_lines.append("        \n")
        new_lines.append("        applyTheme();\n")
        new_lines.append("        \n")
        new_lines.append("        const l = $('loading-screen');\n")
        new_lines.append("        if(l) {\n")
        new_lines.append("            l.style.opacity=0;\n")
        new_lines.append("            setTimeout(() => l.remove(), 500);\n")
        new_lines.append("            $('app').classList.remove('opacity-0');\n")
        new_lines.append("        }\n")
        new_lines.append("        \n")
        new_lines.append("        if(!currentUser) render();\n")
        new_lines.append("    } catch (e) {\n")
        new_lines.append("        console.error(&quot;Turso Init Error:&quot;, e);\n")
        new_lines.append("        // If Turso is not available, fall back to local mode\n")
        new_lines.append("        const l = $('loading-screen');\n")
        new_lines.append("        if(l) {\n")
        new_lines.append("            l.style.opacity=0;\n")
        new_lines.append("            setTimeout(() => l.remove(), 500);\n")
        new_lines.append("            $('app').classList.remove('opacity-0');\n")
        new_lines.append("        }\n")
        new_lines.append("        if(!currentUser) render();\n")
        new_lines.append("    }\n")
        new_lines.append("}\n")
        new_lines.append("\n")
        new_lines.append("async function saveDB() {\n")
        new_lines.append("    try {\n")
        new_lines.append("        const dataJson = JSON.stringify(db);\n")
        new_lines.append("        const now = new Date().toISOString();\n")
        new_lines.append("        \n")
        new_lines.append("        await turso.execute({\n")
        new_lines.append("            sql: `\n")
        new_lines.append("                INSERT INTO app_data (id, data, updated_at) \n")
        new_lines.append("                VALUES (?, ?, ?)\n")
        new_lines.append("                ON CONFLICT(id) DO UPDATE SET \n")
        new_lines.append("                    data = excluded.data,\n")
        new_lines.append("                    updated_at = excluded.updated_at\n")
        new_lines.append("            `,\n")
        new_lines.append("            args: ['master_record', dataJson, now]\n")
        new_lines.append("        });\n")
        new_lines.append("\n")
        new_lines.append("        // Show sync indicator\n")
        new_lines.append("        const status = $('sync-status');\n")
        new_lines.append("        if(status) {\n")
        new_lines.append("            status.style.opacity = '1';\n")
        new_lines.append("            setTimeout(() => status.style.opacity = '0', 2000);\n")
        new_lines.append("        }\n")
        new_lines.append("    } catch (e) {\n")
        new_lines.append("        console.error(&quot;Save Error:&quot;, e);\n")
        new_lines.append("        showToast('Failed to save data: ' + e.message, 'error');\n")
        new_lines.append("    }\n")
        new_lines.append("}\n")
        new_lines.append("\n")
        new_lines.append("initTurso();\n")
        # Skip until we find initSupabase()
        skip_until = "initSupabase();"
        continue
    
    # Skip initSupabase() call
    if 'initSupabase();' in line:
        continue
    
    # Remove supabaseUser assignment in login
    if 'supabaseUser' in line and 'user.id' in line:
        continue
    
    # Update loading text
    if 'CONNECTING...' in line:
        new_lines.append('    <p class="font-bold tracking-widest">LOADING...</p>\n')
        continue
    
    # Add all other lines
    new_lines.append(line)

# Write the updated content
with open('index_turso.html', 'w', encoding='utf-8') as f:
    f.writelines(new_lines)

print("✓ Successfully converted to Turso database")