import { Component } from '@angular/core';
import { AddTransactionDesktopSubPage } from '../component/add-transaction-desktop.component';
import { AddTransactionMobileSubPage } from '../component/add-transaction-mobile.component';

@Component({
  standalone: true,
  imports: [AddTransactionDesktopSubPage, AddTransactionMobileSubPage],
  template: `
    <!-- Desktop (≥ 768px) -->
    <div class="hidden md:block">
      <app-add-transaction-desktop></app-add-transaction-desktop>
    </div>

    <!-- Mobile (< 768px) -->
    <div class="block md:hidden">
      <app-add-transaction-mobile></app-add-transaction-mobile>
    </div>
  `,
})
export class AddTransactionPage {}
