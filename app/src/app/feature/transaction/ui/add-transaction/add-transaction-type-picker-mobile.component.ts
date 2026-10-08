import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideArrowDown, LucideUsers } from '@lucide/angular';

type TxType = 'expense' | 'income' | 'debt';

@Component({
  selector: 'app-add-transaction-type-picker-mobile',
  standalone: true,
  imports: [CommonModule, LucideArrowUp, LucideArrowDown, LucideUsers],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="flex gap-2">
      @for (t of txTypes; track t.id) {
        <button type="button" class="type-tile-mobile" [class.sel]="selectedType === t.id"
                (click)="onSelectType(t.id)">
          <div class="w-8 h-8 rounded-[8px] flex items-center justify-center"
               [style.background]="selectedType === t.id ? t.softAccent : 'var(--bw-sunken)'"
               [style.color]="t.accent">
            @if (t.id === 'expense') {
              <svg lucideArrowUp class="w-4 h-4" style="stroke-width:2.4"></svg>
            } @else if (t.id === 'income') {
              <svg lucideArrowDown class="w-4 h-4" style="stroke-width:2.4"></svg>
            } @else {
              <svg lucideUsers class="w-4 h-4" style="stroke-width:2.4"></svg>
            }
          </div>
          <span class="text-[12px] font-bold leading-tight text-center text-bw-ink-2">
            {{ t.label }}
          </span>
        </button>
      }
    </div>
  `,
})
export class AddTransactionTypePickerMobileComponent {
  @Input() txTypes: { id: TxType; label: string; accent: string; softAccent: string }[] = [];
  @Input() selectedType: TxType = 'income';
  @Input() onSelectType: (type: TxType) => void = () => {};
}
