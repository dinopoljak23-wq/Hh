/* ============================================
   BewerbungsPro - App Logic
   ============================================ */

// ---- State ----
let currentStep = 1;
let selectedGender = 'herr';
let uploadedFile = null;
let docxZip = null;
let docxXmlContent = '';
let foundPlaceholders = [];
let usingDefaultTemplate = false;

// Default template content
const DEFAULT_TEMPLATE = `{vorname} {nachname}
{meine_strasse}
{meine_plz} {mein_ort}
Tel.: {telefon}
E-Mail: {email}

{firma}
{abteilung}
{strasse}
{plz} {ort}

{mein_ort}, den {datum}

Bewerbung als {position}{referenz_zeile}

{anrede}

mit großem Interesse habe ich Ihre Stellenanzeige{quelle_text} gelesen und bewerbe mich hiermit um die Position als {position} in Ihrem Unternehmen.

Ich bin überzeugt, dass meine Qualifikationen und Erfahrungen hervorragend zu den Anforderungen der ausgeschriebenen Stelle passen. Gerne möchte ich mein Wissen und meine Fähigkeiten in Ihr Team einbringen und zum Erfolg von {firma} beitragen.

Über die Einladung zu einem persönlichen Vorstellungsgespräch freue ich mich sehr. Gerne überzeuge ich Sie in einem persönlichen Gespräch von meinen Qualifikationen.

Mit freundlichen Grüßen

{vorname} {nachname}`;

// ---- Init ----
document.addEventListener('DOMContentLoaded', () => {
    // Set today's date
    const today = new Date().toISOString().split('T')[0];
    document.getElementById('datum').value = today;

    // Load saved personal data
    loadPersonalData();
    updateAnrede();
    updatePreview();
});

// ---- Step Navigation ----
function goToStep(step) {
    // Validate before moving forward
    if (step > currentStep) {
        if (currentStep === 1 && !uploadedFile && !usingDefaultTemplate) {
            shakeElement(document.getElementById('upload-area'));
            return;
        }
    }

    document.querySelectorAll('.step-content').forEach(s => s.classList.remove('active'));
    document.getElementById('step-' + step).classList.add('active');

    // Update step indicators
    document.querySelectorAll('.step').forEach(s => {
        const sNum = parseInt(s.dataset.step);
        s.classList.remove('active', 'done');
        if (sNum === step) s.classList.add('active');
        else if (sNum < step) s.classList.add('done');
    });

    // Update step lines
    const lines = document.querySelectorAll('.step-line');
    lines.forEach((line, i) => {
        line.classList.toggle('done', i < step - 1);
    });

    currentStep = step;

    if (step === 3) {
        generatePreview();
    }

    window.scrollTo({ top: 0, behavior: 'smooth' });
}

function shakeElement(el) {
    el.style.animation = 'none';
    el.offsetHeight; // trigger reflow
    el.style.animation = 'shake 0.4s ease';
    setTimeout(() => el.style.animation = '', 400);
}

// Add shake animation
const style = document.createElement('style');
style.textContent = `@keyframes shake { 0%,100%{transform:translateX(0)} 25%{transform:translateX(-8px)} 75%{transform:translateX(8px)} }`;
document.head.appendChild(style);

// ---- File Upload ----
function handleFileUpload(event) {
    const file = event.target.files[0];
    if (!file) return;

    if (!file.name.endsWith('.docx')) {
        alert('Bitte nur .docx Dateien hochladen!');
        return;
    }

    uploadedFile = file;
    usingDefaultTemplate = false;

    // Show file info
    document.getElementById('file-name').textContent = file.name;
    document.getElementById('file-size').textContent = formatFileSize(file.size);
    document.getElementById('file-info').classList.remove('hidden');
    document.getElementById('upload-area').style.display = 'none';

    // Parse DOCX
    const reader = new FileReader();
    reader.onload = function(e) {
        JSZip.loadAsync(e.target.result).then(zip => {
            docxZip = zip;
            return zip.file('word/document.xml').async('string');
        }).then(xml => {
            docxXmlContent = xml;
            // Find placeholders
            findPlaceholders(xml);
        }).catch(err => {
            console.error('Error parsing DOCX:', err);
            alert('Fehler beim Lesen der Datei. Ist es eine gültige .docx Datei?');
        });
    };
    reader.readAsArrayBuffer(file);
}

function findPlaceholders(text) {
    // DOCX XML might split placeholders across tags, so clean first
    const cleaned = text.replace(/<[^>]+>/g, '');
    const matches = cleaned.match(/\{([^}]+)\}/g) || [];
    foundPlaceholders = [...new Set(matches)];

    if (foundPlaceholders.length > 0) {
        const container = document.getElementById('placeholder-tags');
        container.innerHTML = foundPlaceholders.map(p =>
            `<span class="tag">${p}</span>`
        ).join('');
        document.getElementById('found-placeholders').classList.remove('hidden');
    }
}

function removeFile() {
    uploadedFile = null;
    docxZip = null;
    docxXmlContent = '';
    foundPlaceholders = [];
    usingDefaultTemplate = false;
    document.getElementById('file-info').classList.add('hidden');
    document.getElementById('found-placeholders').classList.add('hidden');
    document.getElementById('upload-area').style.display = '';
    document.getElementById('file-input').value = '';
}

function useDefaultTemplate() {
    usingDefaultTemplate = true;
    uploadedFile = { name: 'Standard-Vorlage.docx' };

    document.getElementById('file-name').textContent = 'Standard-Vorlage (integriert)';
    document.getElementById('file-size').textContent = 'Bewerbungsanschreiben';
    document.getElementById('file-info').classList.remove('hidden');
    document.getElementById('upload-area').style.display = 'none';

    // Show placeholders from default template
    const matches = DEFAULT_TEMPLATE.match(/\{([^}]+)\}/g) || [];
    foundPlaceholders = [...new Set(matches.filter(m =>
        !['referenz_zeile', 'quelle_text'].includes(m.replace(/[{}]/g, ''))
    ))];

    const container = document.getElementById('placeholder-tags');
    container.innerHTML = foundPlaceholders.map(p =>
        `<span class="tag">${p}</span>`
    ).join('');
    document.getElementById('found-placeholders').classList.remove('hidden');
}

// ---- Gender & Anrede ----
function selectGender(gender) {
    selectedGender = gender;
    document.querySelectorAll('.gender-btn').forEach(btn => {
        btn.classList.toggle('active', btn.dataset.gender === gender);
    });

    const nameFields = document.getElementById('name-fields');
    nameFields.style.display = gender === 'none' ? 'none' : '';

    updateAnrede();
    updatePreview();
}

function getAnrede() {
    const titel = document.getElementById('titel').value.trim();
    const nachname = document.getElementById('nachname_ap').value.trim();

    if (selectedGender === 'none') {
        return 'Sehr geehrte Damen und Herren,';
    }

    const geschlecht = selectedGender === 'herr' ? 'Herr' : 'Frau';
    const anredeWort = selectedGender === 'herr' ? 'geehrter' : 'geehrte';

    let name = '';
    if (titel) name += titel + ' ';
    name += nachname || (selectedGender === 'herr' ? 'Müller' : 'Müller');

    return `Sehr ${anredeWort} ${geschlecht} ${name},`;
}

function updateAnrede() {
    document.getElementById('anrede-result').textContent = getAnrede();
}

// ---- Get all form values ----
function getFormValues() {
    const datum = document.getElementById('datum').value;
    const datumFormatted = datum ? new Date(datum + 'T12:00:00').toLocaleDateString('de-DE', {
        day: '2-digit', month: '2-digit', year: 'numeric'
    }) : '';

    const datumLong = datum ? new Date(datum + 'T12:00:00').toLocaleDateString('de-DE', {
        day: 'numeric', month: 'long', year: 'numeric'
    }) : '';

    const referenz = document.getElementById('referenz').value.trim();
    const quelle = document.getElementById('quelle').value.trim();

    return {
        '{firma}': document.getElementById('firma').value.trim(),
        '{abteilung}': document.getElementById('abteilung').value.trim(),
        '{strasse}': document.getElementById('strasse').value.trim(),
        '{plz}': document.getElementById('plz').value.trim(),
        '{ort}': document.getElementById('ort').value.trim(),
        '{ansprechpartner}': getFullAnsprechpartner(),
        '{titel}': document.getElementById('titel').value.trim(),
        '{vorname_ap}': document.getElementById('vorname_ap').value.trim(),
        '{nachname_ap}': document.getElementById('nachname_ap').value.trim(),
        '{anrede}': getAnrede(),
        '{geschlecht}': selectedGender === 'herr' ? 'Herr' : selectedGender === 'frau' ? 'Frau' : '',
        '{position}': document.getElementById('position').value.trim(),
        '{referenz}': referenz,
        '{referenz_zeile}': referenz ? ` (Ref: ${referenz})` : '',
        '{datum}': datumFormatted,
        '{datum_lang}': datumLong,
        '{quelle}': quelle,
        '{quelle_text}': quelle ? ` auf ${quelle}` : '',
        '{vorname}': document.getElementById('vorname').value.trim(),
        '{nachname}': document.getElementById('nachname').value.trim(),
        '{meine_strasse}': document.getElementById('meine_strasse').value.trim(),
        '{meine_plz}': document.getElementById('meine_plz').value.trim(),
        '{mein_ort}': document.getElementById('mein_ort').value.trim(),
        '{email}': document.getElementById('email').value.trim(),
        '{telefon}': document.getElementById('telefon').value.trim(),
    };
}

function getFullAnsprechpartner() {
    if (selectedGender === 'none') return '';
    const titel = document.getElementById('titel').value.trim();
    const vorname = document.getElementById('vorname_ap').value.trim();
    const nachname = document.getElementById('nachname_ap').value.trim();
    const geschlecht = selectedGender === 'herr' ? 'Herrn' : 'Frau';
    let parts = [geschlecht];
    if (titel) parts.push(titel);
    if (vorname) parts.push(vorname);
    if (nachname) parts.push(nachname);
    return parts.join(' ');
}

function updatePreview() {
    updateAnrede();
    savePersonalData();
}

// ---- Save/Load personal data ----
function savePersonalData() {
    const personal = {
        vorname: document.getElementById('vorname').value,
        nachname: document.getElementById('nachname').value,
        meine_strasse: document.getElementById('meine_strasse').value,
        meine_plz: document.getElementById('meine_plz').value,
        mein_ort: document.getElementById('mein_ort').value,
        email: document.getElementById('email').value,
        telefon: document.getElementById('telefon').value,
    };
    localStorage.setItem('bewerbung_personal', JSON.stringify(personal));
}

function loadPersonalData() {
    try {
        const data = JSON.parse(localStorage.getItem('bewerbung_personal'));
        if (!data) return;
        Object.keys(data).forEach(key => {
            const el = document.getElementById(key);
            if (el && data[key]) el.value = data[key];
        });
    } catch {}
}

// ---- Preview Generation ----
function generatePreview() {
    const values = getFormValues();
    const preview = document.getElementById('preview-page');

    if (usingDefaultTemplate) {
        // Generate from default template
        let text = DEFAULT_TEMPLATE;
        Object.keys(values).forEach(key => {
            text = text.split(key).join(values[key] || '___');
        });

        const lines = text.split('\n');
        let html = '';
        lines.forEach(line => {
            if (line.trim() === '') {
                html += '<br>';
            } else {
                html += `<p style="margin:2px 0">${escHtml(line)}</p>`;
            }
        });

        preview.innerHTML = html;
    } else if (docxXmlContent) {
        // Generate from uploaded DOCX
        let processedXml = docxXmlContent;

        // Replace placeholders - handle split across XML tags
        Object.keys(values).forEach(key => {
            const placeholder = key;
            const value = values[key] || '';

            // Direct replacement
            processedXml = processedXml.split(escXml(placeholder)).join(escXml(value));

            // Also try with XML tags potentially splitting the placeholder
            // Build regex that allows XML tags between characters
            const chars = placeholder.split('');
            let regexStr = chars.map(c => escRegex(escXml(c))).join('(?:<[^>]*>)*');
            try {
                const regex = new RegExp(regexStr, 'g');
                processedXml = processedXml.replace(regex, escXml(value));
            } catch {}
        });

        // Convert DOCX XML to simple HTML for preview
        let previewHtml = xmlToHtml(processedXml);
        preview.innerHTML = previewHtml;
    } else {
        preview.innerHTML = '<p style="color:#999; text-align:center; padding:40px;">Keine Vorlage geladen</p>';
    }
}

function xmlToHtml(xml) {
    let html = '';
    // Extract paragraphs
    const paragraphs = xml.match(/<w:p[ >][\s\S]*?<\/w:p>/g) || [];

    paragraphs.forEach(p => {
        // Check for bold
        const isBold = p.includes('<w:b/>') || p.includes('<w:b ');
        // Extract text runs
        let text = '';
        const runs = p.match(/<w:t[^>]*>([^<]*)<\/w:t>/g) || [];
        runs.forEach(r => {
            const match = r.match(/<w:t[^>]*>([^<]*)<\/w:t>/);
            if (match) text += match[1];
        });

        if (text.trim() === '') {
            html += '<br>';
        } else {
            const style = isBold ? 'font-weight:700;' : '';
            html += `<p style="margin:2px 0;${style}">${escHtml(text)}</p>`;
        }
    });

    return html || '<p style="color:#999">Vorschau konnte nicht generiert werden</p>';
}

// ---- PDF Export ----
function exportPDF() {
    const preview = document.getElementById('preview-page');

    const opt = {
        margin: [15, 15, 15, 15],
        filename: generateFilename('pdf'),
        image: { type: 'jpeg', quality: 0.98 },
        html2canvas: { scale: 2, useCORS: true },
        jsPDF: { unit: 'mm', format: 'a4', orientation: 'portrait' }
    };

    // Show loading
    const btn = document.querySelector('.export-btn');
    const originalText = btn.innerHTML;
    btn.innerHTML = '<span class="loading-spinner"></span> PDF wird erstellt...';
    btn.disabled = true;

    // Add spinner style
    if (!document.getElementById('spinner-style')) {
        const s = document.createElement('style');
        s.id = 'spinner-style';
        s.textContent = `
            .loading-spinner {
                width: 18px; height: 18px;
                border: 2px solid rgba(255,255,255,0.3);
                border-top-color: white;
                border-radius: 50%;
                display: inline-block;
                animation: spin 0.6s linear infinite;
            }
            @keyframes spin { to { transform: rotate(360deg); } }
        `;
        document.head.appendChild(s);
    }

    html2pdf().set(opt).from(preview).save().then(() => {
        btn.innerHTML = originalText;
        btn.disabled = false;
    }).catch(() => {
        btn.innerHTML = originalText;
        btn.disabled = false;
        alert('Fehler beim PDF-Export. Bitte versuche es erneut.');
    });
}

// ---- Word Export ----
function exportWord() {
    if (usingDefaultTemplate) {
        // Generate a simple DOCX from default template
        exportDefaultAsWord();
        return;
    }

    if (!docxZip) {
        alert('Keine Word-Vorlage geladen!');
        return;
    }

    const values = getFormValues();
    let processedXml = docxXmlContent;

    Object.keys(values).forEach(key => {
        const value = values[key] || '';
        processedXml = processedXml.split(escXml(key)).join(escXml(value));

        // Handle split placeholders
        const chars = key.split('');
        let regexStr = chars.map(c => escRegex(escXml(c))).join('(?:<[^>]*>)*');
        try {
            const regex = new RegExp(regexStr, 'g');
            processedXml = processedXml.replace(regex, escXml(value));
        } catch {}
    });

    // Replace XML in zip and download
    docxZip.file('word/document.xml', processedXml);
    docxZip.generateAsync({ type: 'blob', mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' })
        .then(blob => {
            downloadBlob(blob, generateFilename('docx'));
        });
}

function exportDefaultAsWord() {
    const values = getFormValues();
    let text = DEFAULT_TEMPLATE;
    Object.keys(values).forEach(key => {
        text = text.split(key).join(values[key] || '');
    });

    // Build minimal DOCX
    const zip = new JSZip();

    // [Content_Types].xml
    zip.file('[Content_Types].xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
        '<Default Extension="xml" ContentType="application/xml"/>' +
        '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
        '</Types>'
    );

    // _rels/.rels
    zip.file('_rels/.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
        '</Relationships>'
    );

    // word/_rels/document.xml.rels
    zip.file('word/_rels/document.xml.rels',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
        '</Relationships>'
    );

    // word/document.xml
    const paragraphs = text.split('\n').map(line => {
        const isBold = line.startsWith('Bewerbung als');
        const escaped = escXml(line);
        return '<w:p><w:r>' +
            (isBold ? '<w:rPr><w:b/></w:rPr>' : '') +
            '<w:t xml:space="preserve">' + escaped + '</w:t></w:r></w:p>';
    }).join('');

    zip.file('word/document.xml',
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
        '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
        '<w:body>' + paragraphs + '</w:body></w:document>'
    );

    zip.generateAsync({ type: 'blob', mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' })
        .then(blob => {
            downloadBlob(blob, generateFilename('docx'));
        });
}

// ---- Helpers ----
function generateFilename(ext) {
    const firma = document.getElementById('firma').value.trim() || 'Bewerbung';
    const position = document.getElementById('position').value.trim();
    const name = document.getElementById('nachname').value.trim();
    let filename = 'Bewerbung';
    if (name) filename += '_' + name;
    if (firma && firma !== 'Bewerbung') filename += '_' + firma;
    if (position) filename += '_' + position;
    return filename.replace(/[^a-zA-Z0-9äöüÄÖÜß_-]/g, '_') + '.' + ext;
}

function downloadBlob(blob, filename) {
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

function formatFileSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
}

function escHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}

function escXml(str) {
    return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;')
              .replace(/"/g, '&quot;').replace(/'/g, '&apos;');
}

function escRegex(str) {
    return str.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
