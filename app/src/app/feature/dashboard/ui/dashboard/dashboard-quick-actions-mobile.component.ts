import { Component, Input } from '@angular/core';
import { CommonModule } from '@angular/common';
import { LucidePlus, LucideUsers, LucideReceipt } from '@lucide/angular';

@Component({
  selector: 'app-dashboard-quick-actions-mobile',
  standalone: true,
  imports: [CommonModule, LucidePlus, LucideUsers, LucideReceipt],
  styleUrls: ['./dashboard-ui.styles.css'],
  template: `
    <div class="grid grid-cols-3 gap-2">
      <button (click)="goToAdd()" class="quick-tile items-center text-center">
        <div class="icon-box mx-auto" style="background:var(--bw-lime-soft)">
          <svg lucidePlus class="w-4 h-4" style="color:var(--bw-lime-ink);stroke-width:2.4"></svg>
        </div>
        <span class="text-[11px] font-semibold text-bw-ink-2">Tambah</span>
      </button>
      <button (click)="goToFriends()" class="quick-tile items-center text-center">
        <div class="icon-box mx-auto" style="background:var(--bw-lime-soft)">
          <svg lucideUsers class="w-4 h-4" style="color:var(--bw-lime-ink);stroke-width:2.2"></svg>
        </div>
        <span class="text-[11px] font-semibold text-bw-ink-2">Tagih</span>
      </button>
      <button (click)="goToFriends()" class="quick-tile items-center text-center">
        <div class="icon-box mx-auto">
          <svg lucideReceipt class="w-4 h-4" style="color:var(--bw-ink-2);stroke-width:2.2"></svg>
        </div>
        <span class="text-[11px] font-semibold text-bw-ink-2">Split</span>
      </button>
    </div>
  `,
})
export class DashboardQuickActionsMobileComponent {
  @Input({ required: true }) goToAdd!: () => void;
  @Input({ required: true }) goToFriends!: () => void;
}
