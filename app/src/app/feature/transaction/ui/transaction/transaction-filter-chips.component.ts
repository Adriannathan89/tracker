import { Component, EventEmitter, Input, Output } from '@angular/core';
import { CommonModule } from '@angular/common';

type FilterType = 'all' | 'expense' | 'income' | 'debt';

@Component({
  selector: 'app-transaction-filter-chips',
  standalone: true,
  imports: [CommonModule],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    @if (variant === 'mobile') {
      <div class="flex gap-2 overflow-x-auto pb-1" style="scrollbar-width:none">
        @for (f of filters; track f.id) {
          <button class="filter-chip shrink-0" [class.active]="activeFilter === f.id" (click)="select.emit(f.id)">
            {{ f.label }}
          </button>
        }
      </div>
    } @else {
      <div class="flex gap-1.5">
        @for (f of filters; track f.id) {
          <button class="filter-chip" [class.active]="activeFilter === f.id" (click)="select.emit(f.id)">
            {{ f.label }}
          </button>
        }
      </div>
    }
  `,
})
export class TransactionFilterChipsComponent {
  @Input() filters: { id: FilterType; label: string }[] = [];
  @Input() activeFilter: FilterType = 'all';
  @Input() variant: 'desktop' | 'mobile' = 'desktop';
  @Output() select = new EventEmitter<FilterType>();
}
