import { Component, signal, inject, OnInit } from '@angular/core';
import { RouterOutlet, Router, NavigationEnd, ActivatedRoute } from '@angular/router';
import { filter } from 'rxjs/operators';
import { SidebarComponent } from './sidebar.component';
import { TopbarComponent } from './topbar.component';
import { BottomNavComponent } from './bottom-nav.component';
import { LucideBell, LucideSun, LucideMoon, LucideLogOut } from '@lucide/angular';
import { SwithTheme } from '../core/service/styles/switch-theme.service';
import { UserAuthService } from '../core/service/user/user-auth.service';

@Component({
  selector: 'app-main-layout',
  standalone: true,
  imports: [RouterOutlet, SidebarComponent, TopbarComponent, BottomNavComponent, LucideBell, LucideSun, LucideMoon, LucideLogOut],
  styles: [`
    .theme-toggle-mobile {
      position: relative;
      width: 50px;
      height: 28px;
      border-radius: 14px;
      border: 1.5px solid var(--bw-border);
      background: var(--bw-elevated);
      display: flex;
      align-items: center;
      cursor: pointer;
      padding: 2px;
      transition: background 0.3s cubic-bezier(0.4, 0, 0.2, 1), border-color 0.3s cubic-bezier(0.4, 0, 0.2, 1);
      flex-shrink: 0;
    }

    .theme-toggle-mobile:hover {
      background: var(--bw-sunken);
    }

    .toggle-thumb-mobile {
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
      transition: left 0.35s cubic-bezier(0.34, 1.56, 0.64, 1), background 0.3s cubic-bezier(0.4, 0, 0.2, 1), box-shadow 0.3s;
      box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
    }

    .theme-toggle-mobile.dark .toggle-thumb-mobile {
      left: 24px;
      background: var(--bw-ink);
      border-color: var(--bw-ink);
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }

    .theme-icon-mobile {
      display: flex;
      align-items: center;
      justify-content: center;
      width: 14px;
      height: 14px;
      color: currentColor;
    }

    .toggle-thumb-mobile .theme-icon-mobile {
      animation: icon-swap-mobile 0.35s cubic-bezier(0.4, 0, 0.2, 1);
    }

    .theme-toggle-mobile.dark .toggle-thumb-mobile .theme-icon-mobile {
      color: var(--bw-on-ink);
    }

    @keyframes icon-swap-mobile {
      0% { opacity: 1; transform: scale(1) rotate(0deg); }
      50% { opacity: 0; transform: scale(0) rotate(-90deg); }
      51% { opacity: 0; transform: scale(0) rotate(90deg); }
      100% { opacity: 1; transform: scale(1) rotate(0deg); }
    }

    .ripple-m {
      position: absolute; inset: 0; border-radius: inherit;
      background: var(--bw-lime); opacity: 0; pointer-events: none;
    }

    .theme-toggle-mobile.toggling .ripple-m {
      animation: btn-ripple-m 0.48s ease-out forwards;
    }

    @keyframes btn-ripple-m {
      0%   { opacity: 0.15; transform: scale(1); }
      100% { opacity: 0;    transform: scale(1.8); }
    }

    @keyframes fade-in {
      from { opacity: 0; transform: translateY(-4px); }
      to { opacity: 1; transform: translateY(0); }
    }

    .animate-fade-in {
      animation: fade-in 0.2s ease-out;
    }
  `],
  template: `
    <div class="flex h-screen overflow-hidden bg-bw-bg">

      <!-- Desktop sidebar -->
      <app-sidebar class="hidden md:flex"></app-sidebar>

      <!-- Main area -->
      <div class="flex flex-col flex-1 min-w-0 overflow-hidden">

        <!-- Desktop topbar -->
        <app-topbar [title]="pageTitle()"></app-topbar>

        <!-- Mobile header -->
        <header class="flex md:hidden items-center justify-between px-5 pt-4 pb-3 bg-bw-bg shrink-0 border-b border-bw-border">
          <div>
            <div class="text-[12px] font-semibold text-bw-ink-3 tracking-[0.04em]">
              {{ todayLabel }}
            </div>
            <h1 class="text-[22px] font-extrabold tracking-[-0.03em] text-bw-ink mt-0.5 leading-none">
              {{ pageTitle() }}
            </h1>
          </div>
          <div class="flex items-center gap-2">
            <!-- Mobile theme toggle -->
            <div class="theme-toggle-mobile" [class.dark]="isDark" [class.toggling]="mAnimating()" (click)="toggleThemeMobile()"
                 [attr.title]="isDark ? 'Mode terang' : 'Mode gelap'" role="button" tabindex="0" (keydown.enter)="toggleThemeMobile()" (keydown.space)="toggleThemeMobile()">
              <span class="ripple-m"></span>
              <div class="toggle-thumb-mobile">
                <span class="theme-icon-mobile">
                  @if (isDark) {
                    <svg lucideSun class="w-3.5 h-3.5"></svg>
                  } @else {
                    <svg lucideMoon class="w-3.5 h-3.5"></svg>
                  }
                </span>
              </div>
            </div>
            <button class="w-10 h-10 rounded-[12px] flex items-center justify-center border border-bw-border bg-bw-surface text-bw-ink-2 cursor-pointer">
              <svg lucideBell class="w-5 h-5"></svg>
            </button>
            <!-- Account menu -->
            <button (click)="toggleAccountMenu()" class="relative w-10 h-10 rounded-[12px] flex items-center justify-center border border-bw-border bg-bw-lime text-bw-ink font-semibold text-[12px] cursor-pointer hover:opacity-90 transition-opacity shrink-0">
              {{ userInitials() }}
            </button>
            @if (showAccountMenu()) {
              <div class="absolute top-14 right-5 z-50 bg-bw-surface border border-bw-border rounded-[12px] shadow-lg overflow-hidden min-w-[160px] animate-fade-in">
                <div class="px-4 py-3 border-b border-bw-border">
                  <div class="text-[13px] font-bold text-bw-ink truncate">{{ username() }}</div>
                </div>
                <button (click)="logout()" class="w-full flex items-center gap-2.5 px-4 py-3 text-[13px] font-semibold text-bw-red hover:bg-bw-sunken transition-colors">
                  <svg lucideLogOut class="w-4 h-4 shrink-0"></svg>
                  Keluar
                </button>
              </div>
            }
          </div>
        </header>

        <!-- Content -->
        <main class="flex-1 overflow-y-auto overflow-x-hidden pb-[76px] md:pb-0">
          <router-outlet></router-outlet>
        </main>

        <!-- Mobile bottom nav -->
        <app-bottom-nav></app-bottom-nav>

      </div>
    </div>
  `,
})
export class MainLayoutComponent implements OnInit {
  private router = inject(Router);
  private route = inject(ActivatedRoute);
  private themeService = inject(SwithTheme);
  private authService = inject(UserAuthService);

  pageTitle = signal('Home');
  mAnimating = signal(false);
  showAccountMenu = signal(false);

  username = signal('');
  userInitials = signal('?');

  get isDark() { return this.themeService.isDark; }

  readonly todayLabel = new Intl.DateTimeFormat('id-ID', {
    weekday: 'long', day: 'numeric', month: 'long',
  }).format(new Date());

  ngOnInit() {
    this.loadUserInfo();
    this.updateTitle();
    this.router.events
      .pipe(filter(e => e instanceof NavigationEnd))
      .subscribe(() => {
        this.updateTitle();
        this.showAccountMenu.set(false);
        this.loadUserInfo();
      });
  }

  toggleAccountMenu() {
    this.showAccountMenu.update(v => !v);
  }

  toggleThemeMobile() {
    if (this.mAnimating()) return;
    this.mAnimating.set(true);
    setTimeout(() => this.themeService.toggleTheme(), 175); // swap at 50% of 0.35s toggle animation
    setTimeout(() => this.mAnimating.set(false), 480); // clear after animations complete
  }

  async logout() {
    this.showAccountMenu.set(false);
    await this.authService.logout();
    localStorage.removeItem('username');
    this.router.navigate(['/login']);
  }

  private loadUserInfo() {
    const u = localStorage.getItem('username') ?? '';
    this.username.set(u);
    this.userInitials.set(u ? u.slice(0, 2).toUpperCase() : '?');
  }

  private updateTitle() {
    const url = this.router.url;
    if (url.includes('dashboard')) this.pageTitle.set('Home');
    else if (url.includes('transaction/add')) this.pageTitle.set('Catat Transaksi');
    else if (url.includes('transaction')) this.pageTitle.set('Transaksi');
    else if (url.includes('friends')) this.pageTitle.set('Teman');
    else this.pageTitle.set('tracker');
  }
}
