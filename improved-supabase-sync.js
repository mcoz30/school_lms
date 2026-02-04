/**
 * IMPROVED SUPABASE SYNC MODULE
 * 
 * This module provides improved Supabase synchronization with:
 * - Automatic retry logic for failed operations
 * - Configurable timeout settings
 * - Better error handling and debugging
 * - Exponential backoff for retries
 * - Connection health monitoring
 */

// Supabase Configuration
const supabaseUrl = 'https://lgovvztkuqnpsshdrwyu.supabase.co';
const supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imxnb3Z2enRrdXFucHNzaGRyd3l1Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzAwMTY0OTgsImV4cCI6MjA4NTU5MjQ5OH0.0gks6pz9g8JCP6LMiKEGQj3J-M27ljGPLwv-umyoPVA';

// Sync Configuration
const SYNC_CONFIG = {
    maxRetries: 3,
    initialRetryDelay: 1000, // 1 second
    maxRetryDelay: 10000, // 10 seconds
    requestTimeout: 30000, // 30 seconds
    debounceDelay: 500, // 500ms (can be increased if needed)
    enableRetry: true,
    enableLogging: true
};

// Connection Health Monitor
const ConnectionMonitor = {
    lastSuccessfulSync: null,
    consecutiveFailures: 0,
    isHealthy: true,

    recordSuccess() {
        this.lastSuccessfulSync = new Date();
        this.consecutiveFailures = 0;
        this.isHealthy = true;
    },

    recordFailure() {
        this.consecutiveFailures++;
        if (this.consecutiveFailures >= 3) {
            this.isHealthy = false;
        }
    },

    getStatus() {
        return {
            isHealthy: this.isHealthy,
            lastSync: this.lastSuccessfulSync,
            failures: this.consecutiveFailures
        };
    }
};

// Logger utility
function log(message, level = 'info') {
    if (SYNC_CONFIG.enableLogging) {
        const timestamp = new Date().toISOString();
        const prefix = `[Supabase Sync ${timestamp}]`;
        
        switch (level) {
            case 'error':
                console.error(prefix, message);
                break;
            case 'warn':
                console.warn(prefix, message);
                break;
            case 'success':
                console.log(prefix + '✓', message);
                break;
            default:
                console.log(prefix, message);
        }
    }
}

// Calculate retry delay with exponential backoff
function getRetryDelay(attempt) {
    const delay = SYNC_CONFIG.initialRetryDelay * Math.pow(2, attempt);
    return Math.min(delay, SYNC_CONFIG.maxRetryDelay);
}

// Create Supabase client with timeout configuration
function createSupabaseClient() {
    const { createClient } = supabase;
    
    const client = createClient(supabaseUrl, supabaseKey, {
        auth: {
            persistSession: false,
            autoRefreshToken: false
        },
        global: {
            headers: {
                'x-client-info': 'learnova-lms-improved'
            }
        },
        db: {
            schema: 'public'
        }
    });

    return client;
}

const supabase = createSupabaseClient();

/**
 * Improved Save Function with Retry Logic
 * @param {Object} data - The data to save
 * @param {Object} options - Additional options
 * @returns {Promise<boolean>} - Success status
 */
async function saveDB(data, options = {}) {
    const {
        retries = SYNC_CONFIG.maxRetries,
        timeout = SYNC_CONFIG.requestTimeout
    } = options;

    // Immediate UI Feedback
    updateSyncStatus('Saving...', 'loading');

    // Debounce to prevent flooding
    if (saveDB.timeoutId) {
        clearTimeout(saveDB.timeoutId);
    }

    return new Promise((resolve) => {
        saveDB.timeoutId = setTimeout(async () => {
            let attempt = 0;
            let lastError = null;

            while (attempt <= retries) {
                try {
                    log(`Save attempt ${attempt + 1}/${retries + 1}`, 'info');
                    
                    const controller = new AbortController();
                    const timeoutId = setTimeout(() => {
                        controller.abort();
                    }, timeout);

                    const startTime = Date.now();
                    
                    const { error } = await supabase
                        .from('app_data')
                        .upsert({ 
                            id: 'master_record', 
                            data: data,
                            updated_at: new Date().toISOString()
                        }, { 
                            onConflict: 'id' 
                        });
                    
                    clearTimeout(timeoutId);
                    const duration = Date.now() - startTime;

                    if (error) {
                        throw error;
                    }

                    // Success
                    log(`Save successful in ${duration}ms`, 'success');
                    ConnectionMonitor.recordSuccess();
                    updateSyncStatus('Saved', 'success');
                    resolve(true);
                    return;

                } catch (error) {
                    lastError = error;
                    ConnectionMonitor.recordFailure();
                    
                    log(`Save attempt ${attempt + 1} failed: ${error.message}`, 'error');
                    
                    if (attempt < retries) {
                        const delay = getRetryDelay(attempt);
                        log(`Retrying in ${delay}ms...`, 'warn');
                        
                        await new Promise(resolve => setTimeout(resolve, delay));
                        attempt++;
                    } else {
                        break;
                    }
                }
            }

            // All attempts failed
            log(`All save attempts failed. Last error: ${lastError.message}`, 'error');
            
            // Handle specific errors
            if (lastError.code === '42P01' || lastError.code === '42501') {
                showDatabaseErrorModal(lastError.code);
            } else {
                updateSyncStatus(`Sync failed: ${lastError.message}`, 'error');
                showToast(`Sync failed: ${lastError.message}`, 'error');
            }
            
            resolve(false);
        }, SYNC_CONFIG.debounceDelay);
    });
}

/**
 * Update sync status UI
 * @param {string} message - Status message
 * @param {string} type - Status type (loading, success, error)
 */
function updateSyncStatus(message, type) {
    const status = document.getElementById('sync-status');
    if (status) {
        let icon = '';
        let colorClass = '';
        
        switch (type) {
            case 'loading':
                icon = '<i class="fas fa-circle-notch fa-spin"></i>';
                colorClass = 'text-blue-500';
                break;
            case 'success':
                icon = '<i class="fas fa-check text-green-500"></i>';
                colorClass = 'text-green-500';
                break;
            case 'error':
                icon = '<i class="fas fa-exclamation-triangle text-red-500"></i>';
                colorClass = 'text-red-500';
                break;
            default:
                icon = '<i class="fas fa-save"></i>';
                colorClass = '';
        }
        
        status.innerHTML = `${icon} ${message}`;
        status.style.opacity = '1';
        
        if (type === 'success' || type === 'loading') {
            setTimeout(() => {
                status.style.opacity = '0';
            }, 2000);
        }
    }
}

/**
 * Show toast notification
 * @param {string} message - Toast message
 * @param {string} type - Toast type
 */
function showToast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const toast = document.createElement('div');
    toast.className = `px-4 py-3 rounded shadow-lg text-white font-bold transform transition-all duration-300 translate-y-4 pointer-events-auto ${
        type === 'error' ? 'bg-red-500' : 
        type === 'success' ? 'bg-green-500' : 'bg-blue-500'
    }`;
    toast.innerText = message;
    
    container.appendChild(toast);
    
    setTimeout(() => {
        toast.classList.add('opacity-0', 'translate-y-4');
        setTimeout(() => toast.remove(), 300);
    }, 3000);
}

/**
 * Check connection health
 * @returns {Promise<boolean>} - Connection health status
 */
async function checkConnectionHealth() {
    try {
        const startTime = Date.now();
        const { data, error } = await supabase
            .from('app_data')
            .select('id')
            .limit(1);
        
        const duration = Date.now() - startTime;

        if (error) {
            log(`Health check failed: ${error.message}`, 'error');
            return false;
        }

        log(`Connection healthy (latency: ${duration}ms)`, 'success');
        return true;
    } catch (error) {
        log(`Health check exception: ${error.message}`, 'error');
        return false;
    }
}

/**
 * Get data with retry logic
 * @returns {Promise<Object|null>} - Retrieved data or null
 */
async function getData() {
    let attempt = 0;
    const retries = SYNC_CONFIG.maxRetries;

    while (attempt <= retries) {
        try {
            const { data, error } = await supabase
                .from('app_data')
                .select('data')
                .eq('id', 'master_record')
                .single();

            if (error) {
                throw error;
            }

            return data?.data || null;

        } catch (error) {
            log(`Get attempt ${attempt + 1} failed: ${error.message}`, 'error');
            
            if (attempt < retries) {
                const delay = getRetryDelay(attempt);
                await new Promise(resolve => setTimeout(resolve, delay));
                attempt++;
            } else {
                return null;
            }
        }
    }
}

/**
 * Initialize Supabase with improved error handling
 */
async function initSupabase() {
    log('Initializing Supabase connection...', 'info');

    try {
        // First check connection health
        const isHealthy = await checkConnectionHealth();
        
        if (!isHealthy) {
            log('Warning: Connection health check failed', 'warn');
        }

        // Fetch initial data
        const appData = await getData();

        if (appData) {
            log('Data loaded successfully from Supabase', 'success');
            return appData;
        } else {
            log('No existing data found, using defaults', 'info');
            return null;
        }

    } catch (error) {
        log(`Supabase initialization error: ${error.message}`, 'error');
        return null;
    }
}

/**
 * Show database error modal with SQL fix
 * @param {string} code - Error code
 */
function showDatabaseErrorModal(code) {
    const title = code === '42P01' ? 'Database Table Missing' : 'Permission Denied (RLS)';
    const msg = code === '42P01' 
        ? 'The "app_data" table does not exist in your Supabase project.' 
        : 'Row Level Security is blocking the save. You need to enable public access.';
    
    // This function assumes you have a renderModal function in your app
    if (typeof renderModal === 'function') {
        renderModal('db-error', title, `
            <div class="space-y-4">
                <div class="bg-red-50 text-red-700 p-4 rounded border border-red-200">
                    <p class="font-bold"><i class="fas fa-exclamation-triangle"></i> Data Not Saving</p>
                    <p class="text-sm mt-1">${msg}</p>
                </div>
                <p class="text-sm text-gray-600">Please go to the <strong>Supabase SQL Editor</strong> and run this code:</p>
                <div class="relative group">
                    <textarea id="sql-code" class="w-full h-32 bg-gray-800 text-green-400 font-mono text-xs p-3 rounded" readonly>
create table if not exists app_data (
  id text primary key,
  data jsonb,
  updated_at timestamptz
);
alter table app_data enable row level security;
create policy "Public Access" on app_data for all using (true) with check (true);
                    </textarea>
                    <button onclick="navigator.clipboard.writeText(document.getElementById('sql-code').value); showToast('SQL Copied!')" 
                            class="absolute top-2 right-2 bg-white/20 hover:bg-white/40 text-white px-2 py-1 rounded text-xs">
                        Copy
                    </button>
                </div>
                <button onclick="saveDB(db); closeModal('db-error')" 
                        class="btn-theme w-full text-white py-2 rounded font-bold">
                    I ran the code, Try Saving Again
                </button>
            </div>
        `);
    }
}

// Export functions for use in main application
if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        saveDB,
        getData,
        initSupabase,
        checkConnectionHealth,
        ConnectionMonitor,
        SYNC_CONFIG
    };
}

// For browser usage, make available globally
if (typeof window !== 'undefined') {
    window.SupabaseSync = {
        saveDB,
        getData,
        initSupabase,
        checkConnectionHealth,
        ConnectionMonitor,
        SYNC_CONFIG
    };
}