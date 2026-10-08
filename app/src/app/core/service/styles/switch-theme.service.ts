import { Injectable } from "@angular/core";

@Injectable({
    providedIn: 'root'
})
export class SwithTheme {
    isDark = false;
    private readonly themeStorageKey = 'theme';

    constructor() { this.initializeTheme(); }

    private initializeTheme(): void {
        this.isDark = this.getInitialTheme();
        this.applyTheme();
    }

    toggleTheme(): void {
        this.isDark = !this.isDark;
        this.applyTheme();
        localStorage.setItem(this.themeStorageKey, this.isDark ? 'dark' : 'light');
    }

    private getInitialTheme(): boolean {
        const savedTheme = localStorage.getItem(this.themeStorageKey);

        if (savedTheme === 'dark') {
            return true;
        }

        if (savedTheme === 'light') {
            return false;
        }

        return window.matchMedia('(prefers-color-scheme: dark)').matches;
    }

    private applyTheme(): void {
        document.documentElement.classList.toggle('bw-dark', this.isDark);
    }
}