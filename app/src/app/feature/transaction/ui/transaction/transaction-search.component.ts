import { Component, EventEmitter, Input, Output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { LucideSearch } from '@lucide/angular';

@Component({
  selector: 'app-transaction-search',
  standalone: true,
  imports: [FormsModule, LucideSearch],
  styleUrls: ['./transaction-ui.styles.css'],
  template: `
    <div class="relative w-full">
      <svg lucideSearch class="absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-bw-ink-3" style="pointer-events:none"></svg>
      <input class="bw-input" placeholder="Cari transaksi…"
             [ngModel]="query" (ngModelChange)="queryChange.emit($event)" />
    </div>
  `,
})
export class TransactionSearchComponent {
  @Input() query = '';
  @Output() queryChange = new EventEmitter<string>();
}
