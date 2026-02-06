# Security Guidelines for LearnNovaLMS

## 🔒 Security Overview

This document outlines security best practices for deploying and maintaining LearnNovaLMS with Supabase.

## ⚠️ Critical Security Practices

### 1. Never Commit Sensitive Data

**NEVER commit these files to Git:**
- Service Role Keys
- Database passwords
- JWT secrets
- Private API keys
- User credentials
- `.env` files with secrets

**Example of what to EXCLUDE:**
```gitignore
# In .gitignore
.env
.supabase-config.js
secrets/
credentials.json
```

### 2. Use Environment Variables

For production deployments, always use environment variables:

**GitHub Pages (via GitHub Actions):**
```yaml
# .github/workflows/deploy.yml
env:
  SUPABASE_URL: ${{ secrets.SUPABASE_URL }}
  SUPABASE_ANON_KEY: ${{ secrets.SUPABASE_ANON_KEY }}
```

**Netlify:**
```
Settings > Environment Variables
- SUPABASE_URL
- SUPABASE_ANON_KEY
```

**Vercel:**
```
Settings > Environment Variables
- SUPABASE_URL
- SUPABASE_ANON_KEY
```

### 3. Row Level Security (RLS)

**ALWAYS enable RLS on all tables in Supabase:**

```sql
-- Enable RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
-- etc. for all tables
```

**Key RLS Policies to Implement:**

1. **Users can only update their own profile:**
```sql
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid()::text = id::text);
```

2. **Students can only view their own grades:**
```sql
CREATE POLICY "Students can view own grades" ON grades
    FOR SELECT USING (student_id = auth.uid()::text::uuid);
```

3. **Teachers can only manage their own courses:**
```sql
CREATE POLICY "Teachers can manage courses" ON subjects
    FOR ALL USING (
        teacher_id = auth.uid()::text::uuid
    );
```

### 4. Supabase Authentication

**Enable Supabase Auth for production:**

1. **Enable Email Confirmation:**
   - Go to Authentication > Providers > Email
   - Enable "Confirm email"

2. **Set Up Email Templates:**
   - Customize confirmation emails
   - Add your school branding

3. **Implement Proper Login Flow:**
   ```javascript
   const { data, error } = await supabase.auth.signInWithPassword({
     email: 'user@school.edu',
     password: 'secure-password'
   });
   ```

4. **Password Requirements:**
   - Minimum 8 characters
   - Require uppercase, lowercase, numbers
   - Enable password policies in Supabase settings

### 5. API Key Management

**Understanding Supabase Keys:**

| Key Type | Exposure | Usage |
|----------|----------|-------|
| `anon` key | Safe | Client-side, public |
| `service_role` key | NEVER | Server-side only, full access |
| `database_url` | NEVER | Direct database access |

**✅ SAFE to commit:**
- `anon` key (it's designed for public use)

**❌ NEVER commit:**
- `service_role` key
- Database password
- JWT secret

### 6. Data Validation

**Always validate on both client AND server:**

```javascript
// Client-side validation
function validateGrade(grade, maxPoints) {
    if (grade < 0 || grade > maxPoints) {
        throw new Error('Invalid grade value');
    }
    return true;
}

// Server-side (Supabase RLS)
CREATE POLICY "Valid grade range" ON grades
    FOR INSERT WITH CHECK (
        grade_value >= 0 AND 
        grade_value <= max_points
    );
```

### 7. Input Sanitization

**Sanitize all user inputs:**

```javascript
// Example: Sanitize post content
function sanitizeContent(content) {
    // Remove script tags
    content = content.replace(/<script\b[^<]*(?:(?!<\/script>)<[^<]*)<\/script>/gi, '');
    // Remove dangerous HTML
    content = content.replace(/<iframe\b[^<]*(?:(?!<\/iframe>)<[^<]*)<\/iframe>/gi, '');
    return content;
}
```

### 8. HTTPS Only

**Always use HTTPS in production:**

- GitHub Pages: Automatically HTTPS
- Netlify: Auto-redirects HTTP to HTTPS
- Vercel: Automatically HTTPS
- Custom domain: Install SSL certificate (Let's Encrypt recommended)

### 9. Rate Limiting

**Enable rate limiting in Supabase:**

```sql
-- Add rate limiting middleware
-- Or use Supabase Dashboard > Database > Extensions
-- Install: pg_stat_statements for monitoring
```

### 10. Audit Logging

**Track important actions:**

```sql
CREATE TABLE audit_log (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id),
    action VARCHAR(100) NOT NULL,
    table_name VARCHAR(50) NOT NULL,
    record_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address INET,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

## 🔐 Authentication Security

### Password Security

**Current State (Demo):**
- Simple plaintext passwords for demo purposes

**Production Recommendations:**
```javascript
// 1. Use Supabase Auth
const { data, error } = await supabase.auth.signUp({
  email: 'user@school.edu',
  password: 'SecurePass123!'
});

// 2. Enable email verification
// In Supabase Dashboard > Authentication > Providers > Email
// Check "Confirm email"

// 3. Implement password reset
await supabase.auth.resetPasswordForEmail('user@school.edu');
```

### Session Management

```javascript
// Check for existing session
const { data: { session } } = await supabase.auth.getSession();

// Monitor auth state changes
supabase.auth.onAuthStateChange((event, session) => {
    if (event === 'SIGNED_IN') {
        console.log('User signed in:', session.user);
    } else if (event === 'SIGNED_OUT') {
        console.log('User signed out');
    }
});
```

### Role-Based Access Control

**Implement strict role checks:**

```javascript
function checkRole(requiredRole) {
    if (!currentUser) return false;
    if (currentUser.role !== requiredRole) {
        showToast('Access denied', 'error');
        return false;
    }
    return true;
}

// Usage
if (!checkRole('teacher')) {
    return; // Stop execution
}
```

## 🛡️ Data Protection

### Sensitive Data Handling

**Never store sensitive data in plain text:**

```sql
-- ❌ BAD
CREATE TABLE users (
    password TEXT -- Plain text password
);

-- ✅ GOOD (using Supabase Auth)
-- Supabase Auth handles password hashing automatically
-- No need to store passwords in your users table
```

### Data Encryption

**For extra security:**

```javascript
// Encrypt sensitive data before storage
function encryptData(data, key) {
    // Use a client-side encryption library
    // Example: crypto-js
    return CryptoJS.AES.encrypt(data, key).toString();
}

// Decrypt when reading
function decryptData(encryptedData, key) {
    return CryptoJS.AES.decrypt(encryptedData, key).toString(CryptoJS.enc.Utf8);
}
```

### Backup Security

**Secure your database backups:**

1. **Enable Point-in-Time Recovery** in Supabase
2. **Regular manual backups** with encryption
3. **Store backups in secure location** (not in git)
4. **Test restore procedures** regularly

## 🔍 Monitoring & Auditing

### Access Logs

```javascript
// Log important actions
async function logAction(action, details) {
    await supabase.from('audit_log').insert({
        user_id: currentUser?.id,
        action: action,
        details: details,
        ip_address: await getIPAddress(),
        user_agent: navigator.userAgent
    });
}
```

### Error Handling

**Never expose sensitive errors to users:**

```javascript
// ❌ BAD
try {
    await saveToSupabase(data);
} catch (error) {
    showToast(error.message, 'error'); // Exposes database errors
}

// ✅ GOOD
try {
    await saveToSupabase(data);
} catch (error) {
    console.error('Detailed error:', error); // Log to console
    showToast('An error occurred. Please try again.', 'error'); // Generic message
}
```

## 📋 Security Checklist

### Before Deployment:

- [ ] Changed default passwords
- [ ] Enabled RLS on all tables
- [ ] Reviewed all RLS policies
- [ ] Removed hardcoded credentials
- [ ] Set up environment variables
- [ ] Enabled email verification
- [ ] Configured password policies
- [ ] Tested authentication flow
- [ ] Reviewed data validation
- [ ] Implemented audit logging
- [ ] Enabled HTTPS
- [ ] Configured CORS settings
- [ ] Set up monitoring/alerts

### Ongoing:

- [ ] Regular security updates
- [ ] Monitor access logs
- [ ] Review user permissions
- [ ] Test backup/restore procedures
- [ ] Stay updated on security patches

## 🚨 Common Security Mistakes

### ❌ DON'T:

1. **Hardcode credentials in code**
   ```javascript
   // ❌ NEVER DO THIS
   const API_KEY = 'sk-1234567890abcdef';
   ```

2. **Disable RLS for convenience**
   ```sql
   -- ❌ NEVER DO THIS
   ALTER TABLE users DISABLE ROW LEVEL SECURITY;
   ```

3. **Use service_role key in client**
   ```javascript
   // ❌ NEVER DO THIS
   const supabase = createClient(URL, SERVICE_ROLE_KEY);
   ```

4. **Ignore input validation**
   ```javascript
   // ❌ NEVER DO THIS
   const userInput = req.body.content;
   db.query(`INSERT INTO posts (content) VALUES ('${userInput}')`);
   ```

5. **Store passwords in plain text**
   ```sql
   -- ❌ NEVER DO THIS
   INSERT INTO users (password) VALUES ('plaintext123');
   ```

### ✅ DO:

1. **Use environment variables**
   ```javascript
   // ✅ DO THIS
   const API_KEY = process.env.API_KEY;
   ```

2. **Enable and configure RLS**
   ```sql
   // ✅ DO THIS
   ALTER TABLE users ENABLE ROW LEVEL SECURITY;
   CREATE POLICY "Users can view own profile" ...
   ```

3. **Use anon key in client**
   ```javascript
   // ✅ DO THIS
   const supabase = createClient(URL, ANON_KEY);
   ```

4. **Validate all inputs**
   ```javascript
   // ✅ DO THIS
   const sanitized = sanitizeInput(userInput);
   db.query('INSERT INTO posts (content) VALUES ($1)', [sanitized]);
   ```

5. **Use Supabase Auth**
   ```javascript
   // ✅ DO THIS
   await supabase.auth.signUp({ email, password });
   ```

## 📞 Reporting Security Issues

If you discover a security vulnerability:

1. **DO NOT** create a public issue
2. Email: security@learnnova.com
3. Include details of the vulnerability
4. Allow time to fix before disclosure

## 🔄 Security Updates

Stay informed about:
- Supabase security advisories
- Browser security updates
- JavaScript library updates
- OWASP Top 10 vulnerabilities

---

**Remember:** Security is an ongoing process, not a one-time setup. Regular reviews and updates are essential.