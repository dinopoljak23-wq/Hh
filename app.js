/* ============================================
   SwipeList - App Logic
   ============================================ */

// ---- Categories ----
const CATEGORIES = [
    { id: 'fruits', name: 'Obst & Gemüse', icon: '🥬', color: '#00B894' },
    { id: 'dairy', name: 'Milchprodukte', icon: '🧈', color: '#FDCB6E' },
    { id: 'meat', name: 'Fleisch & Fisch', icon: '🐟', color: '#E17055' },
    { id: 'drinks', name: 'Getränke', icon: '🥤', color: '#0984E3' },
    { id: 'snacks', name: 'Snacks', icon: '🍿', color: '#E84393' },
    { id: 'household', name: 'Haushalt', icon: '🏠', color: '#6C5CE7' },
    { id: 'other', name: 'Sonstiges', icon: '🛍️', color: '#636E72' },
];

const NOTE_COLORS = ['purple', 'blue', 'green', 'orange', 'pink', 'yellow'];
const NOTE_COLOR_CSS = {
    purple: 'linear-gradient(135deg, #6C5CE7, #A855F7)',
    blue: 'linear-gradient(135deg, #0984E3, #74B9FF)',
    green: 'linear-gradient(135deg, #00B894, #55EFC4)',
    orange: 'linear-gradient(135deg, #E17055, #FAB1A0)',
    pink: 'linear-gradient(135deg, #E84393, #FD79A8)',
    yellow: 'linear-gradient(135deg, #FDCB6E, #FFEAA7)',
};

// ---- State ----
let shoppingItems = [];
let notes = [];
let showChecked = true;
let selectedCategory = 'other';
let itemQuantity = 1;
let selectedNoteColor = 'purple';
let editingNoteId = null;
let activeMenuNoteId = null;

// ---- Init ----
document.addEventListener('DOMContentLoaded', () => {
    loadData();
    renderShopping();
    renderNotes();
    buildCategoryChips();
    buildColorPicker();

    // Close context menu on tap outside
    document.addEventListener('click', (e) => {
        if (!e.target.closest('.context-menu') && !e.target.closest('.note-menu-btn')) {
            hideNoteMenu();
        }
    });

    // Enable add button when typing
    document.getElementById('item-name').addEventListener('input', (e) => {
        const btn = document.getElementById('add-item-btn');
        btn.classList.toggle('disabled', !e.target.value.trim());
    });

    document.getElementById('note-title').addEventListener('input', (e) => {
        const btn = document.getElementById('save-note-btn');
        btn.classList.toggle('disabled', !e.target.value.trim());
    });

    // Enter key support
    document.getElementById('item-name').addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && e.target.value.trim()) addItem();
    });

    // Register service worker
    if ('serviceWorker' in navigator) {
        navigator.serviceWorker.register('sw.js').catch(() => {});
    }
});

// ---- Data Persistence ----
function loadData() {
    try {
        const items = localStorage.getItem('swipelist_items');
        const savedNotes = localStorage.getItem('swipelist_notes');
        shoppingItems = items ? JSON.parse(items) : getDefaultItems();
        notes = savedNotes ? JSON.parse(savedNotes) : getDefaultNotes();
    } catch {
        shoppingItems = getDefaultItems();
        notes = getDefaultNotes();
    }
}

function saveItems() {
    localStorage.setItem('swipelist_items', JSON.stringify(shoppingItems));
}

function saveNotes() {
    localStorage.setItem('swipelist_notes', JSON.stringify(notes));
}

function getDefaultItems() {
    return [
        { id: genId(), name: 'Äpfel', category: 'fruits', quantity: 6, checked: false, created: Date.now() },
        { id: genId(), name: 'Bananen', category: 'fruits', quantity: 3, checked: false, created: Date.now() },
        { id: genId(), name: 'Vollmilch', category: 'dairy', quantity: 2, checked: false, created: Date.now() },
        { id: genId(), name: 'Butter', category: 'dairy', quantity: 1, checked: false, created: Date.now() },
        { id: genId(), name: 'Hähnchenbrust', category: 'meat', quantity: 1, checked: false, created: Date.now() },
        { id: genId(), name: 'Mineralwasser', category: 'drinks', quantity: 2, checked: false, created: Date.now() },
        { id: genId(), name: 'Cola Zero', category: 'drinks', quantity: 1, checked: false, created: Date.now() },
        { id: genId(), name: 'Chips', category: 'snacks', quantity: 1, checked: false, created: Date.now() },
    ];
}

function getDefaultNotes() {
    const now = Date.now();
    return [
        { id: genId(), title: 'Willkommen! 👋', content: 'Das ist deine neue Notizen-App. Tippe auf + um eine neue Notiz zu erstellen.', color: 'purple', pinned: true, created: now, updated: now },
        { id: genId(), title: 'Rezept: Pasta', content: 'Spaghetti kochen, Knoblauch anbraten, Tomatensoße dazu, Parmesan drüber. Fertig!', color: 'orange', pinned: false, created: now - 1000, updated: now - 1000 },
        { id: genId(), title: 'Fitness Ziele', content: 'Mo: Brust & Trizeps\nDi: Rücken & Bizeps\nMi: Pause\nDo: Beine\nFr: Schultern', color: 'green', pinned: false, created: now - 2000, updated: now - 2000 },
        { id: genId(), title: 'Geburtstage', content: 'Mama: 15. März\nPapa: 22. Juli\nLisa: 3. September', color: 'pink', pinned: false, created: now - 3000, updated: now - 3000 },
    ];
}

function genId() {
    return Math.random().toString(36).substr(2, 12) + Date.now().toString(36);
}

// ---- Tab Navigation ----
function switchTab(tab) {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));

    document.getElementById(tab + '-view').classList.add('active');
    document.getElementById('tab-' + tab).classList.add('active');
}

// ---- Shopping List ----
function renderShopping() {
    const search = document.getElementById('shopping-search').value.toLowerCase();
    const list = document.getElementById('shopping-list');

    const filtered = shoppingItems.filter(item =>
        !search || item.name.toLowerCase().includes(search)
    );

    const unchecked = filtered.filter(i => !i.checked);
    const checked = filtered.filter(i => i.checked);

    // Update count
    const totalUnchecked = shoppingItems.filter(i => !i.checked).length;
    document.getElementById('shopping-count').textContent = `${totalUnchecked} Artikel übrig`;

    // Badge
    const badge = document.getElementById('shopping-badge');
    if (totalUnchecked > 0) {
        badge.textContent = totalUnchecked;
        badge.classList.remove('hidden');
    } else {
        badge.classList.add('hidden');
    }

    // Clear checked button
    const clearBtn = document.getElementById('clear-checked-btn');
    const hasChecked = shoppingItems.some(i => i.checked);
    clearBtn.classList.toggle('hidden', !hasChecked);

    // Empty state
    if (shoppingItems.length === 0) {
        list.innerHTML = `
            <div class="empty-state">
                <div class="empty-icon purple">🛒</div>
                <h3>Deine Einkaufsliste ist leer</h3>
                <p>Tippe auf + um Artikel hinzuzufügen</p>
            </div>`;
        return;
    }

    let html = '';

    // Group unchecked by category
    const grouped = {};
    unchecked.forEach(item => {
        if (!grouped[item.category]) grouped[item.category] = [];
        grouped[item.category].push(item);
    });

    CATEGORIES.forEach(cat => {
        const items = grouped[cat.id];
        if (!items || items.length === 0) return;

        html += `
            <div class="category-header">
                <span class="cat-icon cat-${cat.id}">${cat.icon}</span>
                <span class="cat-name cat-${cat.id}">${cat.name}</span>
                <span class="cat-count" style="background:${cat.color}15; color:${cat.color}">${items.length}</span>
            </div>`;

        items.forEach(item => {
            html += renderItemRow(item, cat);
        });
    });

    // Checked section
    if (checked.length > 0) {
        html += `
            <button class="checked-toggle" onclick="toggleCheckedSection()">
                <span class="check-icon">✓</span>
                <span class="check-label">Erledigt (${checked.length})</span>
                <span class="chevron ${showChecked ? 'open' : ''}">▶</span>
            </button>`;

        if (showChecked) {
            checked.forEach(item => {
                const cat = CATEGORIES.find(c => c.id === item.category) || CATEGORIES[6];
                html += renderItemRow(item, cat);
            });
        }
    }

    list.innerHTML = html;
}

function renderItemRow(item, cat) {
    const checkedClass = item.checked ? 'checked' : '';
    const checkboxClass = item.checked ? 'checked' : '';
    const checkSvg = item.checked ?
        `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>` :
        `<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="white" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><path d="M20 6L9 17l-5-5"/></svg>`;

    const qtyBadge = item.quantity > 1 ?
        `<span class="qty-badge" style="background:${cat.color}15; color:${cat.color}">×${item.quantity}</span>` : '';

    return `
        <div class="item-row ${checkedClass}" id="item-${item.id}">
            <div class="checkbox ${checkboxClass}" onclick="toggleItem('${item.id}')">
                ${checkSvg}
            </div>
            <span class="item-name">${escHtml(item.name)}</span>
            ${qtyBadge}
            <button class="delete-btn" onclick="deleteItem('${item.id}')">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round"><path d="M18 6L6 18M6 6l12 12"/></svg>
            </button>
        </div>`;
}

function toggleItem(id) {
    const item = shoppingItems.find(i => i.id === id);
    if (!item) return;
    item.checked = !item.checked;
    saveItems();

    // Animate
    const row = document.getElementById('item-' + id);
    if (row) {
        row.style.transform = 'scale(0.95)';
        row.style.opacity = '0.7';
        setTimeout(() => {
            renderShopping();
        }, 200);
    } else {
        renderShopping();
    }
}

function deleteItem(id) {
    const row = document.getElementById('item-' + id);
    if (row) {
        row.classList.add('removing');
        setTimeout(() => {
            shoppingItems = shoppingItems.filter(i => i.id !== id);
            saveItems();
            renderShopping();
        }, 250);
    } else {
        shoppingItems = shoppingItems.filter(i => i.id !== id);
        saveItems();
        renderShopping();
    }
}

function clearChecked() {
    shoppingItems = shoppingItems.filter(i => !i.checked);
    saveItems();
    renderShopping();
}

function toggleCheckedSection() {
    showChecked = !showChecked;
    renderShopping();
}

// ---- Add Item Modal ----
function buildCategoryChips() {
    const container = document.getElementById('category-chips');
    container.innerHTML = CATEGORIES.map(cat => {
        const sel = cat.id === selectedCategory;
        return `<button class="chip" id="chip-${cat.id}" onclick="selectCategory('${cat.id}')"
            style="background:${sel ? cat.color : cat.color + '1A'}; color:${sel ? '#fff' : cat.color}">
            <span>${cat.icon}</span> ${cat.name}
        </button>`;
    }).join('');
}

function selectCategory(id) {
    selectedCategory = id;
    buildCategoryChips();
}

function changeQty(delta) {
    itemQuantity = Math.max(1, Math.min(99, itemQuantity + delta));
    document.getElementById('qty-value').textContent = itemQuantity;
}

function openAddItem() {
    document.getElementById('add-item-modal').classList.add('open');
    document.getElementById('item-name').value = '';
    itemQuantity = 1;
    document.getElementById('qty-value').textContent = '1';
    selectedCategory = 'other';
    buildCategoryChips();
    document.getElementById('add-item-btn').classList.add('disabled');
    setTimeout(() => document.getElementById('item-name').focus(), 300);
}

function closeAddItem() {
    document.getElementById('add-item-modal').classList.remove('open');
}

function addItem() {
    const name = document.getElementById('item-name').value.trim();
    if (!name) return;

    shoppingItems.unshift({
        id: genId(),
        name,
        category: selectedCategory,
        quantity: itemQuantity,
        checked: false,
        created: Date.now()
    });

    saveItems();
    renderShopping();
    closeAddItem();
}

function closeModal(e, modalId) {
    if (e.target === e.currentTarget) {
        document.getElementById(modalId).classList.remove('open');
        editingNoteId = null;
    }
}

// ---- Notes ----
function renderNotes() {
    const search = document.getElementById('notes-search').value.toLowerCase();
    const grid = document.getElementById('notes-grid');

    const sorted = [...notes].sort((a, b) => {
        if (a.pinned !== b.pinned) return a.pinned ? -1 : 1;
        return b.updated - a.updated;
    });

    const filtered = sorted.filter(n =>
        !search ||
        n.title.toLowerCase().includes(search) ||
        n.content.toLowerCase().includes(search)
    );

    // Update count
    document.getElementById('notes-count').textContent =
        `${notes.length} ${notes.length === 1 ? 'Notiz' : 'Notizen'}`;

    if (notes.length === 0) {
        grid.innerHTML = `
            <div class="empty-state" style="grid-column: 1/-1">
                <div class="empty-icon violet">📝</div>
                <h3>Noch keine Notizen</h3>
                <p>Tippe auf + um eine Notiz zu erstellen</p>
            </div>`;
        return;
    }

    grid.innerHTML = filtered.map(note => {
        const date = new Date(note.updated);
        const dateStr = date.toLocaleDateString('de-DE', { day: 'numeric', month: 'short' }) +
            ', ' + date.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
        const pinHtml = note.pinned ? '<span class="pin-icon">📌</span>' : '';
        const contentHtml = escHtml(note.content).replace(/\n/g, '<br>');

        return `
            <div class="note-card note-${note.color}" id="note-${note.id}" onclick="openEditNote('${note.id}')">
                <div class="note-top">
                    ${pinHtml}
                    <button class="note-menu-btn" onclick="event.stopPropagation(); showNoteMenu(event, '${note.id}')">⋯</button>
                </div>
                <div class="note-title">${escHtml(note.title)}</div>
                <div class="note-text">${contentHtml}</div>
                <div class="note-date">${dateStr}</div>
            </div>`;
    }).join('');
}

// ---- Note Context Menu ----
function showNoteMenu(e, noteId) {
    e.preventDefault();
    activeMenuNoteId = noteId;
    const menu = document.getElementById('note-menu');
    const note = notes.find(n => n.id === noteId);

    document.getElementById('pin-label').textContent = note.pinned ? 'Lösen' : 'Anheften';

    const rect = e.target.getBoundingClientRect();
    menu.style.top = rect.bottom + 4 + 'px';
    menu.style.right = (window.innerWidth - rect.right) + 'px';
    menu.style.left = 'auto';
    menu.classList.remove('hidden');
}

function hideNoteMenu() {
    document.getElementById('note-menu').classList.add('hidden');
    activeMenuNoteId = null;
}

function pinNote() {
    if (!activeMenuNoteId) return;
    const note = notes.find(n => n.id === activeMenuNoteId);
    if (note) {
        note.pinned = !note.pinned;
        saveNotes();
        renderNotes();
    }
    hideNoteMenu();
}

function deleteNote() {
    if (!activeMenuNoteId) return;
    const card = document.getElementById('note-' + activeMenuNoteId);
    if (card) {
        card.classList.add('removing');
        const id = activeMenuNoteId;
        hideNoteMenu();
        setTimeout(() => {
            notes = notes.filter(n => n.id !== id);
            saveNotes();
            renderNotes();
        }, 250);
    } else {
        notes = notes.filter(n => n.id !== activeMenuNoteId);
        saveNotes();
        renderNotes();
        hideNoteMenu();
    }
}

// ---- Add/Edit Note Modal ----
function buildColorPicker() {
    const container = document.getElementById('note-color-picker');
    container.innerHTML = NOTE_COLORS.map(color => {
        const sel = color === selectedNoteColor ? 'selected' : '';
        return `<div class="color-dot ${sel}" style="background:${NOTE_COLOR_CSS[color]}"
            onclick="selectNoteColor('${color}')"></div>`;
    }).join('');
}

function selectNoteColor(color) {
    selectedNoteColor = color;
    buildColorPicker();

    // Update button gradient
    const btn = document.getElementById('save-note-btn');
    if (!btn.classList.contains('disabled')) {
        btn.style.background = NOTE_COLOR_CSS[color];
    }
}

function openAddNote() {
    editingNoteId = null;
    selectedNoteColor = 'purple';
    document.getElementById('note-modal-title').textContent = 'Neue Notiz';
    document.getElementById('note-title').value = '';
    document.getElementById('note-content').value = '';
    document.getElementById('save-note-btn').textContent = 'Speichern';
    document.getElementById('save-note-btn').classList.add('disabled');
    document.getElementById('save-note-btn').style.background = '';
    buildColorPicker();
    document.getElementById('add-note-modal').classList.add('open');
    setTimeout(() => document.getElementById('note-title').focus(), 300);
}

function openEditNote(id) {
    const note = notes.find(n => n.id === id);
    if (!note) return;

    editingNoteId = id;
    selectedNoteColor = note.color;
    document.getElementById('note-modal-title').textContent = 'Notiz bearbeiten';
    document.getElementById('note-title').value = note.title;
    document.getElementById('note-content').value = note.content;
    document.getElementById('save-note-btn').textContent = 'Aktualisieren';
    document.getElementById('save-note-btn').classList.remove('disabled');
    document.getElementById('save-note-btn').style.background = NOTE_COLOR_CSS[note.color];
    buildColorPicker();
    document.getElementById('add-note-modal').classList.add('open');
}

function closeAddNote() {
    document.getElementById('add-note-modal').classList.remove('open');
    editingNoteId = null;
}

function saveNote() {
    const title = document.getElementById('note-title').value.trim();
    const content = document.getElementById('note-content').value.trim();
    if (!title) return;

    if (editingNoteId) {
        const note = notes.find(n => n.id === editingNoteId);
        if (note) {
            note.title = title;
            note.content = content;
            note.color = selectedNoteColor;
            note.updated = Date.now();
        }
    } else {
        notes.unshift({
            id: genId(),
            title,
            content,
            color: selectedNoteColor,
            pinned: false,
            created: Date.now(),
            updated: Date.now()
        });
    }

    saveNotes();
    renderNotes();
    closeAddNote();
}

// ---- Helpers ----
function escHtml(str) {
    const div = document.createElement('div');
    div.textContent = str;
    return div.innerHTML;
}
