package main

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"

	"github.com/jackc/pgx/v5"
)

type debugQuery struct {
	Label string          `json:"label"`
	Rows  json.RawMessage `json:"rows"`
	Error string          `json:"error,omitempty"`
}

func rowsToJSON(rows pgx.Rows) (json.RawMessage, error) {
	fields := rows.FieldDescriptions()
	var records []map[string]interface{}
	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			return nil, err
		}
		rec := make(map[string]interface{}, len(fields))
		for i, f := range fields {
			rec[string(f.Name)] = values[i]
		}
		records = append(records, rec)
	}
	if records == nil {
		records = []map[string]interface{}{}
	}
	data, err := json.Marshal(records)
	if err != nil {
		return nil, err
	}
	return data, nil
}

func (q *DBQueries) debugDump(ctx context.Context) []debugQuery {
	queries := []struct {
		Label string
		SQL   string
	}{
		{"participants", "SELECT id, kind FROM public.participants ORDER BY id"},
		{"profiles", "SELECT participant_id, user_id, display_name, phone_number, upi_id, created_at FROM public.profiles ORDER BY participant_id"},
		{"lists", "SELECT id, account_number, name, created_by, created_at FROM public.lists ORDER BY created_at DESC"},
		{"list_members", "SELECT list_id, participant_id, added_at FROM public.list_members ORDER BY list_id"},
		{"expenses", "SELECT id, list_id, payer_id, amount, category, note, split_type, version, created_at FROM public.expenses ORDER BY created_at DESC"},
		{"expense_splits", "SELECT id, expense_id, participant_id, share_amount, raw_input FROM public.expense_splits ORDER BY expense_id"},
		{"contacts", "SELECT participant_id, display_name, phone_number, created_by, claimed_by_participant_id, created_at FROM public.contacts ORDER BY created_at DESC"},
	}

	var results []debugQuery
	for _, qr := range queries {
		rows, err := q.pool.Query(ctx, qr.SQL)
		if err != nil {
			results = append(results, debugQuery{Label: qr.Label, Error: err.Error()})
			continue
		}
		data, err := rowsToJSON(rows)
		rows.Close()
		if err != nil {
			results = append(results, debugQuery{Label: qr.Label, Error: err.Error()})
			continue
		}
		results = append(results, debugQuery{Label: qr.Label, Rows: data})
	}
	return results
}

func debugAPIHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		data := q.debugDump(r.Context())
		writeJSON(w, http.StatusOK, data)
	}
}

func debugPageHandler(q *DBQueries) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		fmt.Fprint(w, debugHTML)
	}
}

var debugHTML = `<!DOCTYPE html>
<html lang="en">
<head><meta charset="UTF-8"><title>Settl DB Debug</title>
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { font-family: system-ui, -apple-system, sans-serif; background: #0f0f0f; color: #e0e0e0; padding: 20px; }
  h1 { font-size: 1.5rem; margin-bottom: 8px; color: #fff; }
  .controls { margin-bottom: 20px; display: flex; gap: 12px; align-items: center; flex-wrap: wrap; }
  .controls label { font-size: 0.85rem; color: #999; }
  .controls input { background: #1a1a1a; border: 1px solid #333; color: #e0e0e0; padding: 6px 10px; border-radius: 6px; font-size: 0.85rem; width: 300px; }
  .controls button { background: #2563eb; color: #fff; border: none; padding: 6px 14px; border-radius: 6px; cursor: pointer; font-size: 0.85rem; }
  .controls button:hover { background: #1d4ed8; }
  .controls .status { font-size: 0.8rem; color: #666; }
  .table-section { margin-bottom: 24px; }
  .table-section h2 { font-size: 1.1rem; margin-bottom: 6px; color: #94a3b8; font-family: monospace; }
  .table-section .error { color: #ef4444; font-size: 0.85rem; }
  table { border-collapse: collapse; font-size: 0.8rem; width: 100%; font-family: monospace; }
  th { background: #1a1a2e; color: #94a3b8; padding: 6px 10px; text-align: left; border: 1px solid #222; font-weight: 600; }
  td { padding: 4px 10px; border: 1px solid #222; max-width: 300px; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
  tr:nth-child(even) { background: #0a0a0a; }
  tr:hover { background: #1a1a2e; }
  .count { font-size: 0.75rem; color: #666; margin-left: 8px; }
  .copy { background: none; border: 1px solid #444; color: #999; padding: 2px 8px; border-radius: 4px; cursor: pointer; font-size: 0.7rem; margin-left: 8px; }
  .copy:hover { border-color: #888; color: #fff; }
  .toast { position: fixed; bottom: 20px; right: 20px; background: #1a1a2e; color: #94a3b8; padding: 8px 16px; border-radius: 8px; font-size: 0.8rem; border: 1px solid #333; opacity: 0; transition: opacity 0.3s; }
  .toast.show { opacity: 1; }
</style></head>
<body>
<h1>Settl DB Debug</h1>
<div class="controls">
  <label>API URL</label>
  <input id="apiUrl" value="https://settl-kru1.onrender.com" placeholder="https://settl-kru1.onrender.com">
  <label>Token</label>
  <input id="token" value="dev_token" placeholder="Bearer token">
  <button onclick="loadData()">Refresh</button>
  <span id="status" class="status"></span>
</div>
<div id="tables"></div>
<div id="toast" class="toast"></div>
<script>
async function loadData() {
  const base = document.getElementById('apiUrl').value.replace(/\/+$/, '');
  const token = document.getElementById('token').value;
  const status = document.getElementById('status');
  const tables = document.getElementById('tables');
  status.textContent = 'Loading...';
  try {
    const res = await fetch(base + '/api/v1/debug/data', {
      headers: { 'Authorization': 'Bearer ' + token }
    });
    if (!res.ok) { status.textContent = 'HTTP ' + res.status; return; }
    const data = await res.json();
    renderTables(data);
    status.textContent = 'Updated ' + new Date().toLocaleTimeString();
  } catch (e) {
    status.textContent = 'Error: ' + e.message;
  }
}

function renderTables(data) {
  const container = document.getElementById('tables');
  container.innerHTML = '';
  for (const t of data) {
    const section = document.createElement('div');
    section.className = 'table-section';
    const h2 = document.createElement('h2');
    h2.textContent = t.label;
    if (t.error) {
      const err = document.createElement('div');
      err.className = 'error';
      err.textContent = t.error;
      section.appendChild(h2); section.appendChild(err); container.appendChild(section);
      continue;
    }
    const rows = t.rows || [];
    const count = document.createElement('span');
    count.className = 'count';
    count.textContent = rows.length + ' rows';
    h2.appendChild(count);
    const copyBtn = document.createElement('button');
    copyBtn.className = 'copy';
    copyBtn.textContent = 'Copy';
    copyBtn.onclick = function() { copyJSON(t.rows); };
    h2.appendChild(copyBtn);
    section.appendChild(h2);
    if (rows.length === 0) { container.appendChild(section); continue; }
    const table = document.createElement('table');
    const thead = document.createElement('thead');
    const tr = document.createElement('tr');
    const cols = Object.keys(rows[0]);
    for (const c of cols) { const th = document.createElement('th'); th.textContent = c; tr.appendChild(th); }
    thead.appendChild(tr); table.appendChild(thead);
    const tbody = document.createElement('tbody');
    for (const row of rows) {
      const r = document.createElement('tr');
      for (const c of cols) {
        const td = document.createElement('td');
        let v = row[c];
        if (v === null) v = 'NULL';
        else if (typeof v === 'object') v = JSON.stringify(v);
        td.textContent = String(v);
        r.appendChild(td);
      }
      tbody.appendChild(r);
    }
    table.appendChild(tbody); section.appendChild(table); container.appendChild(section);
  }
}

function copyJSON(data) {
  navigator.clipboard.writeText(JSON.stringify(data, null, 2));
  const toast = document.getElementById('toast');
  toast.textContent = 'Copied!';
  toast.classList.add('show');
  setTimeout(() => toast.classList.remove('show'), 2000);
}

loadData();
</script></body></html>`
