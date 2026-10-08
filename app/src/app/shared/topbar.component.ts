import { Component, Input, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { LucidePlus, LucideBell, LucideSun, LucideMoon } from '@lucide/angular';
import { SwithTheme } from '../core/service/styles/switch-theme.service';

@Component({
  selector: 'app-topbar',
  standalone: true,
  imports: [LucidePlus, LucideBell, LucideSun, LucideMoon],
  styles: [`
    :host { display: block; width: 100%; flex-shrink: 0; }

    .theme-toggle {
      position: relative;
      width: 50px; height: 28px;
      border-radius: 14px;
      border: 1.5px solid var(--bw-border);
      background: var(--bw-elevated);
      display: flex;
      align-items: center;
      cursor: pointer;
      padding: 2px;
      transition: background 0.3s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.3s;
      flex-shrink: 0;
    }

    .theme-toggle:hover {
      background: var(--bw-sunken);
    }

    .theme-toggle.dark {
      background: var(--bw-elevated);
    }

    .toggle-thumb {
      position: absolute;
      width: 22px;
      height: 22px;
      border-radius: 10px;
      background: var(--bw-surface);
      border: 1px solid var(--bw-border);
      display: flex;
      align-items: center;
      justify-content: center;
      left: 2px;
      top: 2px;
      transition: left 0.38s cubic-bezier(0.34, 1.56, 0.64, 1), background 0.35s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.35s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.35s cubic-bezier(0.4, 0, 0.2, 1);
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .theme-toggle.dark .toggle-thumb {
      left: 24px;
      background: var(--bw-ink);
      border-color: var(--bw-ink);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }

    .theme-icon {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 14px;
      height: 14px;
      color: currentColor;
    }

    .toggle-thumb .theme-icon {
      animation: icon-swap 0.35s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .theme-toggle.dark .toggle-thumb .theme-icon {
      color: var(--bw-on-ink);
    }

    @keyframes icon-swap {
      0% { opacity: 1; transform: scale(1) rotate(0deg); }
      50% { opacity: 0; transform: scale(0) rotate(-90deg); }
      51% { opacity: 0; transform: scale(0) rotate(90deg); }
      100% { opacity: 1; transform: scale(1) rotate(0deg); }
    }

    .ripple {
      position: absolute; inset: 0; border-radius: inherit;
      background: var(--bw-lime); opacity: 0; pointer-events: none;
    }

    .theme-toggle.toggling .ripple {
      animation: btn-ripple 0.48s ease-out forwards;
    }

    @keyframes btn-ripple {
      0%   { opacity: 0.15; transform: scale(1); }
      100% { opacity: 0;    transform: scale(1.8); }
    }
  `],
  template: `
    <header class="hidden md:flex items-center justify-between px-8 py-5 border-b border-bw-border bg-bw-surface shrink-0">
      <div>
        <div class="text-[11px] font-semibold tracking-[0.08em] uppercase text-bw-ink-3">tracker</div>
        <h1 class="text-[22px] font-bold tracking-[-0.03em] text-bw-ink mt-0.5 leading-none">{{ title }}</h1>
      </div>

      <div class="flex items-center gap-3">
        <!-- Theme toggle -->
        <div class="theme-toggle" [class.dark]="isDark" [class.toggling]="animating()" (click)="toggleTheme()"
             [attr.title]="isDark ? 'Mode terang' : 'Mode gelap'" role="button" tabindex="0" (keydown.enter)="toggleTheme()" (keydown.space)="toggleTheme()">
          <span class="ripple"></span>
          <div class="toggle-thumb">
            <span class="theme-icon">
              @if (isDark) {
                <svg lucideSun class="w-3.5 h-3.5"></svg>
              } @else {
                <svg lucideMoon class="w-3.5 h-3.5"></svg>
              }
            </span>
          </div>
        </div>

        <button class="flex items-center justify-center w-9 h-9 rounded-[10px] border border-bw-border text-bw-ink-2 hover:bg-bw-sunken transition-colors cursor-pointer">
          <svg lucideBell class="w-4 h-4"></svg>
        </button>

        <button (click)="goToAdd()"
          class="flex items-center gap-1.5 px-3.5 py-2 rounded-[10px] bg-bw-ink text-bw-on-ink text-[13px] font-semibold hover:opacity-90 transition-opacity cursor-pointer">
          <svg lucidePlus class="w-4 h-4 shrink-0"></svg>
          Catat transaksi
        </button>
      </div>
    </header>
  `,
})
export class TopbarComponent {
  @Input() title = 'Home';
  private themeService = inject(SwithTheme);
  private router = inject(Router);

  animating = signal(false);

  get isDark() { return this.themeService.isDark; }

  toggleTheme() {
    if (this.animating()) return;
    this.animating.set(true);
    setTimeout(() => this.themeService.toggleTheme(), 175); // swap theme at 50% of toggle animation
    setTimeout(() => this.animating.set(false), 480); // clear after all animations complete
  }

  goToAdd() { this.router.navigate(['/transaction/add']); }
}
