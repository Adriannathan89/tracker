import { Component, Input, Output, EventEmitter } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideArrowDown, LucideUsers } from '@lucide/angular';
import { Record } from '../../../../core/model/record.model';
import { getCategoryColors } from '../../../../core/lib/category-colors';

interface TxGroup {
  label: string;
  total: number;
  items: Record[];
}

@Component({
  selector: 'app-transaction-group-list-desktop',
  standalone: true,
  imports: [CommonModule, LucideArrowUp, LucideArrowDown, LucideUsers],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    @for (g of groups; track g.label) {
      <div class="bw-card overflow-hidden animate-fade-slide-up">
        <div class="flex justify-between items-center px-4 py-3 bg-bw-elevated border-b border-bw-border">
          <span class="text-[13px] font-bold text-bw-ink">{{ g.label }}</span>
          <span class="mono text-[12px] font-semibold"
                [style.color]="g.total < 0 ? 'var(--bw-red)' : 'var(--bw-green)'">
            {{ g.total < 0 ? '−' : '+' }}Rp {{ formatRupiah(abs(g.total)) }}
          </span>
        </div>
        @for (tx of g.items; track tx.id; let i = $index) {
          <div class="flex items-center gap-3.5 px-4 py-3.5"
               [class.tx-row]="i > 0"
               [style.opacity]="tx.isCommitted ? '1' : '0.6'"
               [style.cursor]="tx.isCommitted ? 'default' : 'pointer'"
               (click)="tx.isCommitted ? null : commitRecord.emit(tx)">
            <div class="icon-box">
              @if (tx.type === 'expense') {
                <svg lucideArrowUp class="w-[18px] h-[18px]" style="color:var(--bw-red);stroke-width:1.8"></svg>
              } @else if (tx.type === 'income') {
                <svg lucideArrowDown class="w-[18px] h-[18px]" style="color:var(--bw-green);stroke-width:1.8"></svg>
              } @else {
                <svg lucideUsers class="w-[18px] h-[18px]" style="color:var(--bw-amber);stroke-width:1.8"></svg>
              }
            </div>
            <div class="flex-1 min-w-0">
              <div class="flex items-center gap-2">
                <span class="text-[14px] font-semibold text-bw-ink truncate">{{ tx.title }}</span>
                @if (!tx.isCommitted) {
                  <span class="text-[10px] font-semibold px-2 py-0.5 rounded-full shrink-0"
                        style="background:var(--bw-amber-soft);color:var(--bw-amber)">
                    Belum dikonfirmasi
                  </span>
                }
              </div>
              <div class="flex items-center gap-1.5 mt-0.5">
                @for (cat of tx.categories; track cat.id; let i = $index) {
                  @if (cat.type === 'primary') {
                    <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full"
                          [style.background]="getCategoryColors(cat.name)[0]"
                          [style.color]="getCategoryColors(cat.name)[1]">
                      {{ cat.name }}
                    </span>
                  } @else if (cat.type === 'secondary') {
                    <span class="text-[10px] font-semibold px-1.5 py-0.5 rounded-full"
                          [style.background]="getCategoryColors(tx.categories[0]?.name || '')[0]"
                          [style.color]="getCategoryColors(tx.categories[0]?.name || '')[1]"
                          style="opacity: 0.75">
                      · {{ cat.name }}
                    </span>
                  }
                }
                @if (tx.description) {
                  <span class="text-[12px] text-bw-ink-3 truncate">{{ tx.description }}</span>
                }
              </div>
            </div>
            <span class="text-[12px] font-medium px-2.5 py-0.5 rounded-full shrink-0"
                  [style.background]="typeChipBg(tx.type)"
                  [style.color]="typeChipColor(tx.type)">
              {{ typeLabel(tx.type) }}
            </span>
            <div class="text-[12px] text-bw-ink-3 w-[120px] text-right shrink-0">{{ formatTime(tx.createdAt) }}</div>
            <div class="mono text-[15px] font-bold w-[140px] text-right shrink-0"
                 [style.color]="tx.type === 'expense' ? 'var(--bw-red)' : 'var(--bw-green)'">
              {{ tx.type === 'expense' ? '−' : '+' }}Rp {{ formatRupiah(tx.amount) }}
            </div>
          </div>
        }
      </div>
    }
  `,
})
export class TransactionGroupListDesktopComponent {
  @Input() groups: TxGroup[] = [];
  @Input() formatRupiah!: (n: number) => string;
  @Input() formatTime!: (dateStr: string) => string;
  @Input() typeLabel!: (type: string) => string;
  @Input() typeChipBg!: (type: string) => string;
  @Input() typeChipColor!: (type: string) => string;
  @Output() commitRecord = new EventEmitter<Record>();

  abs = (value: number) => Math.abs(value);
  getCategoryColors = getCategoryColors;
}
