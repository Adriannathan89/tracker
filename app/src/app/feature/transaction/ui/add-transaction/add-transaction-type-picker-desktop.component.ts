import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucideArrowUp, LucideArrowDown, LucideUsers, LucideCheck } from '@lucide/angular';

type TxType = 'expense' | 'income' | 'debt';

@Component({
  selector: 'app-add-transaction-type-picker-desktop',
  standalone: true,
  imports: [CommonModule, LucideArrowUp, LucideArrowDown, LucideUsers, LucideCheck],
  styleUrls: ['./add-transaction.styles.css'],
  template: `
    <div class="grid grid-cols-3 gap-2.5">
      @for (t of txTypes; track t.id) {
        <button type="button" class="type-tile-desktop" [class.sel]="selectedType === t.id"
                (click)="onSelectType(t.id)">
          <div class="w-9 h-9 rounded-[10px] flex items-center justify-center"
               [style.background]="selectedType === t.id ? t.softAccent : 'var(--bw-sunken)'"
               [style.color]="t.accent">
            @if (t.id === 'expense') {
              <svg lucideArrowUp class="w-[18px] h-[18px]" style="stroke-width:2.4"></svg>
            } @else if (t.id === 'income') {
              <svg lucideArrowDown class="w-[18px] h-[18px]" style="stroke-width:2.4"></svg>
            } @else {
              <svg lucideUsers class="w-[18px] h-[18px]" style="stroke-width:2.4"></svg>
            }
          </div>
          <div class="text-[16px] font-bold">{{ t.label }}</div>
          @if (selectedType === t.id) {
            <div class="absolute top-4 right-4">
              <svg lucideCheck class="w-[18px] h-[18px]" style="color:var(--bw-lime)"></svg>
            </div>
          }
        </button>
      }
    </div>
  `,
})
export class AddTransactionTypePickerDesktopComponent {
  @Input() txTypes: { id: TxType; label: string; accent: string; softAccent: string }[] = [];
  @Input() selectedType: TxType = 'income';
  @Input() onSelectType: (type: TxType) => void = () => {};
}
