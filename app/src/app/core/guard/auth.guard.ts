import { inject } from "@angular/core";
import { CanActivateFn } from "@angular/router";
import { UserAuthService } from "../service/user/user-auth.service";
import { Router } from "@angular/router";

export const authGuard: CanActivateFn = async () => {
    const auth = inject(UserAuthService);
    const router = inject(Router);

    if(await auth.isAuthenticated()) {
        return true;
    }

    router.navigate(['/login']);
    return false;
}