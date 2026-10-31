// Solves the acw_sc__v2 cookie challenge from Aliyun WAF
const fs = require('fs');

function solveAcw(html) {
    const match = html.match(/var\s+arg1\s*=\s*['"]([A-Za-z0-9]+)['"]/);
    if (!match) return null;
    const arg1 = match[1];

    // Simulate mock document
    let cookieVal = null;
    const mockDocument = {
        set cookie(val) {
            cookieVal = val;
        },
        get cookie() {
            return cookieVal;
        },
        location: {
            reload() {}
        }
    };

    // Extract script content
    const scriptMatch = html.match(/<script>(.*?)<\/script>/s);
    if (!scriptMatch) return null;
    let code = scriptMatch[1];
    
    // Replace document with mockDocument
    code = code.replace(/document\[/g, 'mockDocument[').replace(/document\./g, 'mockDocument.');

    const vm = require('vm');
    const sandbox = {
        mockDocument,
        window: {},
        Date,
        parseInt,
        Math,
        String,
        RegExp,
        decodeURIComponent
    };
    vm.createContext(sandbox);
    try {
        vm.runInContext(code, sandbox);
    } catch (e) {
        // Even if some DOM check throws after cookie set, check if cookieVal was assigned
    }

    if (cookieVal) {
        const cMatch = cookieVal.match(/acw_sc__v2=([0-9a-fA-F]+)/);
        if (cMatch) return cMatch[1];
    }
    return null;
}

if (process.argv[2]) {
    const html = fs.readFileSync(process.argv[2], 'utf8');
    const token = solveAcw(html);
    console.log(token);
}

module.exports = { solveAcw };

