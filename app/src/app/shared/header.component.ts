import { Component } from "@angular/core";
import { SwithTheme } from "../core/service/styles/switch-theme.service";
import { Router } from "@angular/router";
import { NavbarComponent } from "./navbar.component";
import { CommonModule } from "@angular/common";
import { UserAuthService } from "../core/service/user/user-auth.service";
import { LucideLogOut, LucideMoon, LucideSun } from "@lucide/angular";

@Component({
    selector: 'app-header',
    standalone: true,
    imports: [NavbarComponent, CommonModule, LucideSun, LucideMoon, LucideLogOut],
    template: `
        <div class="w-full h-20 bg-primary-color text-text-color flex items-center justify-between py-4 md:px-4 shadow-b-md border-b border-secondary-color">
            <div class="max-sm:text-sm xl:text-2xl max-sm:mt-[4px] flex font-bold ml-6">
                <p>tracker</p>
            </div>
            <div class="flex gap-[32px] md:mr-6 mr-2">
                <button
                type="button"
                (click)="toggleTheme()"
                role="switch"
                [attr.aria-checked]="isDark"
                [attr.aria-label]="isDark ? 'Switch to light mode' : 'Switch to dark mode'"
                class="relative inline-flex w-16 xl:w-18 items-center rounded-full border border-text-color bg-secondary-color px-1 transition-colors duration-300 cursor-pointer
                mt-[5px]"
                >

                <span
                    class="w-full h-full max-h-6 max-w-6 rounded-full bg-primary-color shadow-md transition-transform duration-300 flex items-center justify-center"
                    [ngClass]="isDark ? 'translate-x-[30px] xl:translate-x-[38px]' : 'translate-y-0'">
                    <svg lucideSun [class.hidden]="isDark" class="h-3.5 w-3.5 text-secondary-color" aria-hidden="true"></svg>
                    <svg lucideMoon [class.hidden]="!isDark" class="h-4 w-4 text-secondary-color" aria-hidden="true"></svg>
                </span>
                </button>
                <div class="flex max-xl:gap-[20px] gap-[32px]">
                    @if(isLogin) {
                        <app-navbar></app-navbar>
                        <div>
                            <button
                        (click)="toggleUserMenu()"
                        class="max-sm:text-sm max-sm:mt-[8px] md:text-md md:mt-[8px] xl:text-xl mt-[4px] cursor-pointer">
                            {{ username }}
                        </button>
                        @if(userMenu) {
                            <div class="absolute z-5 top-15 right-10 bg-card-color rounded-lg shadow-md p-4">

                                <button class="w-full text-left p-2 cursor-pointer flex items-center gap-2" (click)="logout()">
                                    <svg lucideLogOut class="h-4 w-4" aria-hidden="true"></svg>
                                    <span>Logout</span>
                                </button>
                            </div>
                        }
                        </div>
                    } @else {
                        <button class="py-2 px-3 w-[94px] h-[40px] shadow-md rounded-3xl bg-card-color cursor-pointer text-card-color" (click)="login()">Login</button>
                    }
                </div>
            </div>

        </div>
    `
})
export class HeaderComponent {
    userMenu: boolean = false;


    constructor(
        private switchThemeService: SwithTheme,
        private router: Router,
        private userAuthService: UserAuthService
    ) {}

    get isDark(): boolean {
        return this.switchThemeService.isDark;
    }

    get isLogin(): boolean {
        return localStorage.getItem('username') !== null;
    }

    get username(): string {
        return localStorage.getItem('username') || '';
    }

    toggleUserMenu() {
        this.userMenu = !this.userMenu;
    }

    toggleTheme(): void {
        this.switchThemeService.toggleTheme();
    }

    login(): void {
        this.router.navigate(['/login']);
    }

    logout(): void {
        localStorage.removeItem('username');
        this.userAuthService.logout();
        this.router.navigate(['/login']);
    }
}
