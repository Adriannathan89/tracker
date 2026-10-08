import { Component, HostListener } from "@angular/core";
import { ElementRef } from "@angular/core";
import { Router } from "@angular/router";

@Component({
    selector: 'app-navbar',
    template: `
        <div class="hidden md:flex md:gap-[32px] mt-[4px] font-semibold text-text-card-color">
            <div>
                <button class="p-2 w-[16px]
                w-full
                md:w-auto max-md:text-xs
                xl:min-w-[160px] xl:text-md
                bg-card-color rounded-lg cursor-pointer"
                (click)="routerNavigate('/dashboard')">
                Dashboard</button>
            </div>
            <div>
                <button class="p-2 w-[16px]
                w-full
                md:w-auto max-md:text-xs
                xl:min-w-[160px] xl:text-md
                bg-card-color rounded-lg cursor-pointer"
                (click)="routerNavigate('/friends')">
                Friends</button>
            </div>
            <div>
                <button class="p-2 w-[16px]
                w-full
                md:w-auto max-md:text-xs
                xl:min-w-[160px] xl:text-md
                bg-card-color rounded-lg cursor-pointer"
                (click)="routerNavigate('/transaction')">
                Transaction</button>
            </div>
        </div>

        <button class="md:hidden mt-[4px] text-2xl cursor-pointer" (click)="toggleMenu()">☰</button>
        @if(menuOpen) {
            <div class="absolute z-10 top-18 right-10 bg-card-color rounded-lg shadow-md p-4 flex flex-col gap-[16px] md:hidden">
                <button class="p-2 w-full text-left bg-card-color rounded-lg cursor-pointer" (click)="routerNavigate('/dashboard')">Dashboard</button>
                <button class="p-2 w-full text-left bg-card-color rounded-lg cursor-pointer" (click)="routerNavigate('/friends')">Friends</button>
                <button class="p-2 w-full text-left bg-card-color rounded-lg cursor-pointer" (click)="routerNavigate('/transaction')">Transaction</button>
            </div>
        }

    `,
})
export class NavbarComponent {
    menuOpen = false;

    constructor(private el: ElementRef, private router: Router) {}

    toggleMenu() {
        this.menuOpen = !this.menuOpen;
    }

    @HostListener('document:click', ['$event'])
    onClick(event: Event) {
        if (!this.el.nativeElement.contains(event.target)) {
            this.menuOpen = false;
        }
    }

    routerNavigate(location: string) {
        this.router.navigate([location]);
    }
}
