import { Component, Input, signal, computed, HostListener } from '@angular/core';
import { LucideArrowDown, LucideArrowUp, LucideZap } from '@lucide/angular';

type Direction = 'receivable' | 'debt';

const QUICK_AMOUNTS = [
  { label: '+10rb', value: 10_000 },
  { label: '+25rb', value: 25_000 },
  { label: '+50rb', value: 50_000 },
  { label: '+100rb', value: 100_000 },
  { label: '+250rb', value: 250_000 },
  { label: '+500rb', value: 500_000 },
];

@Component({
  selector: 'app-add-debt-form',
  standalone: true,
  imports: [LucideArrowDown, LucideArrowUp, LucideZap],
  styles: [`
    .direction-toggle {
      display: inline-flex;
      padding: 4px;
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 999px;
      gap: 0;
      margin-bottom: 18px;
    }

    .direction-btn {
      padding: 8px 16px;
      border-radius: 999px;
      background: transparent;
      color: var(--bw-ink-3);
      border: none;
      cursor: pointer;
      font-size: 13px;
      font-weight: 600;
      display: inline-flex;
      align-items: center;
      gap: 6px;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .direction-btn.active {
      background: var(--bw-ink);
      color: var(--bw-emerald);
    }

    .amount-hero {
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 18px;
      padding: 24px 20px;
      text-align: center;
      margin-bottom: 18px;
    }

    .amount-label {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.1em;
      text-transform: uppercase;
      color: var(--bw-ink-3);
    }

    .amount-display {
      font-family: 'JetBrains Mono', monospace;
      font-size: 48px;
      font-weight: 800;
      letter-spacing: -0.04em;
      margin-top: 4px;
      color: var(--bw-ink);
    }

    .amount-caret {
      display: inline-block;
      color: var(--bw-ink-3);
      margin-left: 2px;
      animation: blink 1s steps(2) infinite;
    }

    @keyframes blink {
      0% { opacity: 1; }
      50% { opacity: 0; }
      100% { opacity: 1; }
    }

    .quick-chip-clear {
      color: var(--bw-red);
      border-color: var(--bw-red-soft);
    }

    .amount-prefix {
      color: var(--bw-ink-3);
    }

    .quick-chips {
      display: flex;
      gap: 6px;
      margin-top: 12px;
      flex-wrap: wrap;
      justify-content: center;
    }

    .quick-chip {
      padding: 6px 12px;
      border: 1px solid var(--bw-border);
      background: var(--bw-surface);
      color: var(--bw-ink-2);
      font-size: 12px;
      font-weight: 600;
      border-radius: 12px;
      cursor: pointer;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .quick-chip:hover {
      background: var(--bw-sunken);
    }

    .form-field {
      margin-bottom: 18px;
    }

    .form-label {
      font-size: 13px;
      font-weight: 600;
      color: var(--bw-ink-2);
      margin-bottom: 8px;
      display: block;
    }

    .form-input {
      width: 100%;
      padding: 14px 16px;
      border: 1px solid var(--bw-border);
      border-radius: 12px;
      background: var(--bw-elevated);
      color: var(--bw-ink);
      font-size: 15px;
      outline: none;
      transition: all 0.2s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .form-input:focus {
      border-color: var(--bw-ink);
      background: var(--bw-surface);
    }

    .form-input::placeholder {
      color: var(--bw-ink-3);
    }

    .preview-card {
      background: var(--bw-emerald-soft);
      border-radius: 12px;
      padding: 14px;
      margin-top: 18px;
      display: flex;
      gap: 12px;
      align-items: center;
    }

    .preview-icon {
      width: 32px;
      height: 32px;
      border-radius: 10px;
      background: var(--bw-ink);
      color: var(--bw-emerald);
      display: flex;
      align-items: center;
      justify-content: center;
      flex-shrink: 0;
    }

    .preview-text {
      font-size: 13px;
      font-weight: 400;
      color: var(--bw-emerald-ink);
      line-height: 1.4;
    }

    .preview-text strong {
      font-weight: 600;
    }

    @media (max-width: 767px) {
      .amount-display {
        font-size: 38px;
      }

      .quick-chips {
        gap: 4px;
      }

      .quick-chip {
        padding: 6px 10px;
        font-size: 11px;
      }

      .preview-icon {
        width: 28px;
        height: 28px;
      }

      .preview-text {
        font-size: 12px;
      }
    }
  `],
  template: `
    <div class="form-content">
      <!-- Direction toggle -->
      <div class="direction-toggle">
        <button type="button" class="direction-btn" [class.active]="direction() === 'receivable'"
          (click)="setDirection('receivable')">
          <svg lucideArrowDown class="w-3.5 h-3.5"></svg>
          Dia hutang ke aku
        </button>
        <button type="button" class="direction-btn" [class.active]="direction() === 'debt'"
          (click)="setDirection('debt')">
          <svg lucideArrowUp class="w-3.5 h-3.5"></svg>
          Aku hutang ke dia
        </button>
      </div>

      <!-- Amount hero -->
      <div class="amount-hero">
        <div class="amount-label">Nominal — ketik angka di keyboard</div>
        <div class="amount-display">
          <span class="amount-prefix">Rp </span>{{ formattedAmount() }}<span class="amount-caret">|</span>
        </div>
        <div class="quick-chips">
          @for (q of quickAmounts; track q.value) {
            <button type="button" class="quick-chip" (click)="addAmount(q.value)">{{ q.label }}</button>
          }
          <button type="button" class="quick-chip quick-chip-clear" (click)="clearAmount()">Hapus</button>
        </div>
      </div>

      <!-- Description -->
      <div class="form-field">
        <label class="form-label">Deskripsi</label>
        <input type="text" class="form-input" placeholder="Misal: Makan malam bersama"
          [value]="description()"
          (input)="onDescriptionChange($event)">
      </div>

      <!-- Date -->
      <div class="form-field">
        <label class="form-label">Tanggal</label>
        <input type="date" class="form-input" [value]="date()" (input)="onDateChange($event)"
          style="font-size: 14px;">
      </div>

      <!-- Live preview -->
      @if (amount() > 0) {
        <div class="preview-card">
          <div class="preview-icon">
            <svg lucideZap class="w-4 h-4" style="stroke-width: 2.4;"></svg>
          </div>
          <div class="preview-text" [innerHTML]="previewText()"></div>
        </div>
      }
    </div>
  `,
})
export class AddDebtFormComponent {
  @Input() friendName = '';

  readonly quickAmounts = QUICK_AMOUNTS;

  direction = signal<Direction>('receivable');
  amount = signal(0);
  description = signal('');
  date = signal(this.todayISO());

  formattedAmount = computed(() => {
    const v = this.amount();
    return v === 0 ? '0' : new Intl.NumberFormat('id-ID').format(v);
  });

  previewText = computed(() => {
    const dir = this.direction();
    const name = this.friendName;
    const nominal = this.formattedAmount();
    if (dir === 'receivable') {
      return `Setelah disimpan, <strong>${name}</strong> akan hutang ke kamu <strong>Rp ${nominal}</strong>`;
    } else {
      return `Setelah disimpan, kamu akan hutang ke <strong>${name}</strong> sebesar <strong>Rp ${nominal}</strong>`;
    }
  });

  setDirection(dir: Direction) { this.direction.set(dir); }
  addAmount(value: number) { this.amount.update(v => Math.min(v + value, 999_999_999)); }
  clearAmount() { this.amount.set(0); }

  onDescriptionChange(event: Event) {
    this.description.set((event.target as HTMLInputElement).value);
  }

  onDateChange(event: Event) {
    this.date.set((event.target as HTMLInputElement).value);
  }

  @HostListener('document:keydown', ['$event'])
  onGlobalKeyDown(event: KeyboardEvent) {
    const target = event.target as HTMLElement | null;
    const inTextField = target instanceof HTMLInputElement || target instanceof HTMLTextAreaElement;
    if (event.ctrlKey || event.metaKey || event.altKey) return;
    if (inTextField) return;

    if (event.key >= '0' && event.key <= '9') {
      this.amount.update(v => Math.min(v * 10 + parseInt(event.key, 10), 999_999_999));
      event.preventDefault();
      return;
    }
    if (event.key === 'Backspace') {
      this.amount.update(v => Math.floor(v / 10));
      event.preventDefault();
      return;
    }
    if (event.key === 'ArrowRight') { this.setDirection('debt'); event.preventDefault(); return; }
    if (event.key === 'ArrowLeft')  { this.setDirection('receivable'); event.preventDefault(); return; }
  }

  private todayISO(): string {
    const d = new Date();
    d.setMinutes(d.getMinutes() - d.getTimezoneOffset());
    return d.toISOString().slice(0, 10);
  }
}