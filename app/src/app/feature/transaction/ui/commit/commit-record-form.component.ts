import { Component, Input, OnInit, signal, computed } from '@angular/core';
import { CommonModule } from '@angular/common';
import { Record } from '../../../../core/model/record.model';
import { getCategoryColors } from '../../../../core/lib/category-colors';

const INCOME_CATEGORIES = new Set(['gaji', 'hadiah']);

const ALL_CATEGORIES = [
  'makanan', 'minuman', 'transport', 'belanja', 'hiburan',
  'tagihan', 'kesehatan', 'gaji', 'hadiah',
];

const CATEGORY_ICONS: { [key: string]: string } = {
  makanan:   '🍜',
  minuman:   '☕',
  transport: '🚗',
  belanja:   '🛍️',
  hiburan:   '🎮',
  tagihan:   '📋',
  kesehatan: '💊',
  gaji:      '💰',
  hadiah:    '🎁',
};

const VALID_SECONDARY_CATEGORIES: { [key: string]: string[] } = {
  'makanan':   ['makanan', 'jajanan'],
  'minuman':   ['minuman', 'jajanan'],
  'transport': ['transport', 'online', 'umum', 'pesawat', 'pribadi'],
  'belanja':   ['belanja', 'fashion', 'elektronik', 'kecantikan', 'online_shop', 'harian'],
  'hiburan':   ['hiburan', 'streaming', 'game', 'liburan', 'tontonan', 'aktivitas'],
  'tagihan':   ['tagihan', 'utilitas', 'internet_pulsa', 'asuransi', 'kredit', 'sewa', 'gaji_pihak3', 'iuran'],
  'kesehatan': ['kesehatan', 'apotek', 'prosedur', 'obat', 'konsul'],
  'gaji':      ['gaji', 'bonus', 'komisi'],
  'hadiah':    ['hadiah', 'undian', 'reward', 'kado', 'sumbangan', 'pemberian_masuk'],
};

@Component({
  selector: 'app-commit-record-form',
  standalone: true,
  imports: [CommonModule],
  styles: [`
    .record-info-card {
      background: var(--bw-elevated);
      border: 1px solid var(--bw-border);
      border-radius: 16px;
      padding: 18px 20px;
      margin-bottom: 20px;
    }

    .record-draft-badge {
      display: inline-flex;
      align-items: center;
      gap: 5px;
      padding: 3px 10px;
      border-radius: 999px;
      background: var(--bw-amber-soft);
      color: var(--bw-amber);
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      margin-bottom: 10px;
    }

    .record-title {
      font-size: 20px;
      font-weight: 800;
      letter-spacing: -0.03em;
      color: var(--bw-ink);
      margin-bottom: 6px;
      line-height: 1.2;
    }

    .record-meta {
      display: flex;
      align-items: center;
      gap: 10px;
      flex-wrap: wrap;
    }

    .record-amount {
      font-family: 'JetBrains Mono', monospace;
      font-size: 22px;
      font-weight: 700;
      letter-spacing: -0.04em;
    }

    .record-date {
      font-size: 12px;
      color: var(--bw-ink-3);
    }

    .record-desc {
      font-size: 12px;
      color: var(--bw-ink-3);
      margin-top: 4px;
    }

    .section-label {
      font-size: 11px;
      font-weight: 700;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--bw-ink-3);
      margin-bottom: 10px;
    }

    .category-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 8px;
      margin-bottom: 16px;
    }

    .cat-btn {
      all: unset;
      cursor: pointer;
      border-radius: 12px;
      padding: 10px 8px;
      display: flex;
      flex-direction: column;
      align-items: center;
      gap: 5px;
      border: 1.5px solid var(--bw-border);
      background: var(--bw-elevated);
      transition: all 0.15s cubic-bezier(0.4, 0, 0.2, 1);
      text-align: center;
    }

    .cat-btn:hover:not(.selected) {
      background: var(--bw-sunken);
      border-color: var(--bw-border-strong);
    }

    .cat-btn.selected {
      border-width: 2px;
    }

    .cat-icon {
      font-size: 18px;
      line-height: 1;
    }

    .cat-name {
      font-size: 10px;
      font-weight: 600;
      color: var(--bw-ink-2);
      line-height: 1;
    }

    .cat-btn.selected .cat-name {
      font-weight: 700;
    }

    .type-badge {
      display: flex;
      align-items: center;
      gap: 8px;
      padding: 12px 16px;
      border-radius: 12px;
      margin-top: 4px;
    }

    .type-dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      flex-shrink: 0;
    }

    .type-text {
      font-size: 13px;
      font-weight: 600;
    }

    .type-sub {
      font-size: 11px;
      margin-left: auto;
      opacity: 0.7;
    }

    @media (max-width: 767px) {
      .record-title {
        font-size: 18px;
      }

      .record-amount {
        font-size: 18px;
      }

      .cat-btn {
        padding: 9px 6px;
      }

      .cat-icon {
        font-size: 16px;
      }
    }
  `],
  template: `
    <!-- Record info card -->
    <div class="record-info-card">
      <div class="record-draft-badge">
        <span>⏳</span>
        <span>Menunggu konfirmasi</span>
      </div>
      <div class="record-title">{{ record.title }}</div>
      <div class="record-meta">
        <span class="record-amount"
              [style.color]="record.type === 'expense' ? 'var(--bw-red)' : 'var(--bw-green)'">
          {{ record.type === 'expense' ? '−' : '+' }}Rp {{ formatRupiah(record.amount) }}
        </span>
        <span class="record-date">{{ formatDate(record.createdAt) }}</span>
      </div>
      @if (record.description) {
        <div class="record-desc">{{ record.description }}</div>
      }
    </div>

    <!-- Category picker -->
    <div class="section-label">Kategori transaksi</div>
    <div class="category-grid">
      @for (cat of allCategories; track cat) {
        <button type="button"
                class="cat-btn"
                [class.selected]="selectedCategory() === cat"
                [style.background]="selectedCategory() === cat ? getCategoryColors(cat)[0] : ''"
                [style.border-color]="selectedCategory() === cat ? getCategoryColors(cat)[1] : ''"
                (click)="selectCategory(cat)">
          <span class="cat-icon">{{ catIcon(cat) }}</span>
          <span class="cat-name" [style.color]="selectedCategory() === cat ? getCategoryColors(cat)[1] : ''">
            {{ cat }}
          </span>
        </button>
      }
    </div>

    <!-- Secondary category picker (only show after primary selected) -->
    @if (selectedCategory() && validSecondaries().length > 0) {
      <div style="margin-top: 20px;">
        <div class="section-label">Kategori detail</div>
        <div class="category-grid">
          @for (cat of validSecondaries(); track cat) {
            <button type="button"
                    class="cat-btn"
                    [class.selected]="selectedSecondary() === cat"
                    [style.background]="selectedSecondary() === cat ? getCategoryColors(cat)[0] : ''"
                    [style.border-color]="selectedSecondary() === cat ? getCategoryColors(cat)[1] : ''"
                    (click)="selectSecondary(cat)">
              <span class="cat-icon">{{ catIcon(cat) }}</span>
              <span class="cat-name" [style.color]="selectedSecondary() === cat ? getCategoryColors(cat)[1] : ''">
                {{ cat }}
              </span>
            </button>
          }
        </div>
      </div>
    }

    <!-- SLM predicted secondary category -->
    @if (predictedSecondary()) {
      <div style="margin-top: 12px; font-size: 11px; color: var(--bw-ink-3);">
        <span style="font-weight: 600;">Prediksi SLM:</span> {{ predictedSecondary() }}
      </div>
    }

    <!-- Derived type indicator -->
    <div class="type-badge"
         [style.background]="derivedType() === 'income' ? 'var(--bw-green-soft)' : 'var(--bw-red-soft)'">
      <div class="type-dot"
           [style.background]="derivedType() === 'income' ? 'var(--bw-green)' : 'var(--bw-red)'">
      </div>
      <span class="type-text"
            [style.color]="derivedType() === 'income' ? 'var(--bw-green)' : 'var(--bw-red)'">
        {{ derivedType() === 'income' ? 'Pemasukan' : 'Pengeluaran' }}
      </span>
      <span class="type-sub"
            [style.color]="derivedType() === 'income' ? 'var(--bw-green)' : 'var(--bw-red)'">
        Otomatis dari kategori
      </span>
    </div>
  `,
})
export class CommitRecordFormComponent implements OnInit {
  @Input() record!: Record;

  readonly allCategories = ALL_CATEGORIES;
  selectedCategory = signal<string>('');

  readonly derivedType = computed<'income' | 'expense'>(() =>
    INCOME_CATEGORIES.has(this.selectedCategory()) ? 'income' : 'expense'
  );

  readonly predictedSecondary = computed<string | undefined>(() => {
    const secondary = this.record.categories.find(c => c.type === 'secondary');
    return secondary?.name;
  });

  selectedSecondary = signal<string>('');

  readonly validSecondaries = computed<string[]>(() => {
    const primary = this.selectedCategory();
    return primary && primary in VALID_SECONDARY_CATEGORIES
      ? VALID_SECONDARY_CATEGORIES[primary]
      : [];
  });

  ngOnInit() {
    const primary = this.record.categories.find(c => c.type === 'primary');
    this.selectedCategory.set(primary?.name ?? '');

    const secondary = this.record.categories.find(c => c.type === 'secondary');
    this.selectedSecondary.set(secondary?.name ?? '');
  }

  selectCategory(cat: string) {
    this.selectedCategory.set(cat);
  }

  // Called from secondary category picker grid in template (Task 2)
  selectSecondary(sec: string) {
    if (this.validSecondaries().includes(sec)) {
      this.selectedSecondary.set(sec);
    }
  }

  private getPrimaryInitialAndCurrent() {
    const primary = this.record.categories.find(c => c.type === 'primary');
    return { initial: primary?.name ?? '', current: this.selectedCategory() };
  }

  getCategoryOrUndefined(): string | undefined {
    const { initial, current } = this.getPrimaryInitialAndCurrent();
    return current !== initial ? current : undefined;
  }

  // Called by CommitRecordSheetComponent to detect changes to both primary and secondary categories
  getCategoryOrUndefinedWithSecondary(): { category?: string; secondary?: string } | undefined {
    const { initial: initialPrimary, current: currentPrimary } = this.getPrimaryInitialAndCurrent();

    const secondary = this.record.categories.find(c => c.type === 'secondary');
    const initialSecondary = secondary?.name ?? '';
    const currentSecondary = this.selectedSecondary();

    const categoryChanged = currentPrimary !== initialPrimary;
    const secondaryChanged = currentSecondary !== initialSecondary;

    if (!categoryChanged && !secondaryChanged) {
      return undefined;
    }

    const result: { category?: string; secondary?: string } = {};
    if (categoryChanged) result.category = currentPrimary;
    if (secondaryChanged) result.secondary = currentSecondary;
    return result;
  }

  getCategoryColors = getCategoryColors;
  catIcon = (cat: string) => CATEGORY_ICONS[cat] ?? '📦';

  formatRupiah = (n: number) => new Intl.NumberFormat('id-ID').format(n);

  formatDate = (dateStr: string): string => {
    if (!dateStr) return '';
    return new Intl.DateTimeFormat('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }).format(new Date(dateStr));
  };
}
