import { Component } from '@angular/core';
import { Router, RouterLink, RouterLinkActive } from '@angular/router';
import { LucideHouse, LucideReceipt, LucidePlus, LucideUsers, LucideWallet } from '@lucide/angular';

@Component({
  selector: 'app-bottom-nav',
  standalone: true,
  imports: [RouterLink, RouterLinkActive, LucideHouse, LucideReceipt, LucidePlus, LucideUsers, LucideWallet],
  styles: [`
    :host { display: block; }
    .fab {
      width: 56px; height: 56px; border-radius: 18px; margin-top: -22px;
      background: var(--bw-ink); color: var(--bw-lime);
      display: flex; align-items: center; justify-content: center;
      box-shadow: var(--bw-shadow-fab);
      border: none; cursor: pointer;
      transition: transform 0.12s ease, opacity 0.12s;
    }
    .fab:active { transform: scale(0.95); }
  `],
  template: `
    <nav class="flex flex md:hidden fixed bottom-0 left-0 right-0 z-50 items-center justify-around bg-bw-surface border-t border-bw-border pb-[env(safe-area-inset-bottom,16px)] pt-2.5 px-3">

      <a [routerLink]="'/dashboard'" routerLinkActive #home="routerLinkActive"
        class="flex flex-col items-center gap-1 px-2.5 py-1 cursor-pointer no-underline"
        [style.color]="home.isActive ? 'var(--bw-ink)' : 'var(--bw-ink-3)'">
        <svg lucideHouse class="w-[22px] h-[22px]"
             [style.strokeWidth]="home.isActive ? '2.2' : '1.8'"></svg>
        <span class="text-[10px] font-semibold">Home</span>
      </a>

      <a [routerLink]="'/transaction'" routerLinkActive #tx="routerLinkActive"
        class="flex flex-col items-center gap-1 px-2.5 py-1 cursor-pointer no-underline"
        [style.color]="tx.isActive ? 'var(--bw-ink)' : 'var(--bw-ink-3)'">
        <svg lucideReceipt class="w-[22px] h-[22px]"
             [style.strokeWidth]="tx.isActive ? '2.2' : '1.8'"></svg>
        <span class="text-[10px] font-semibold">Catatan</span>
      </a>

      <button class="fab" (click)="goToAdd()">
        <svg lucidePlus class="w-7 h-7" style="stroke-width:2.4"></svg>
      </button>

      <a [routerLink]="'/friends'" routerLinkActive #friends="routerLinkActive"
        class="flex flex-col items-center gap-1 px-2.5 py-1 cursor-pointer no-underline"
        [style.color]="friends.isActive ? 'var(--bw-ink)' : 'var(--bw-ink-3)'">
        <svg lucideUsers class="w-[22px] h-[22px]"
             [style.strokeWidth]="friends.isActive ? '2.2' : '1.8'"></svg>
        <span class="text-[10px] font-semibold">Teman</span>
      </a>

      <a [routerLink]="'/dashboard'" routerLinkActive
        class="flex flex-col items-center gap-1 px-2.5 py-1 cursor-pointer no-underline text-bw-ink-3">
        <svg lucideWallet class="w-[22px] h-[22px]" style="stroke-width:1.8"></svg>
        <span class="text-[10px] font-semibold">Saya</span>
      </a>

    </nav>
  `,
})
export class BottomNavComponent {
  constructor(private router: Router) {}
  goToAdd() { this.router.navigate(['/transaction/add']); }
}
