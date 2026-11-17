<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;
use Inovector\MixpostAuth\MixpostAuth;

/**
 * Creates the Mixpost administrator from ADMIN_EMAIL / ADMIN_PASSWORD and keeps the stored hash in step with the
 * variable on every boot, so the credential on the Railway service is always the one that logs in.
 */
class RailwayAdmin extends Command
{
    protected $signature = 'railway:admin';

    protected $description = 'Create or update the administrator from ADMIN_EMAIL and ADMIN_PASSWORD';

    public function handle(): int
    {
        $email = getenv('ADMIN_EMAIL') ?: 'admin@mixpost.example';
        $password = getenv('ADMIN_PASSWORD');

        if (!$password || strlen($password) < 12) {
            $this->error('ADMIN_PASSWORD must be set to at least 12 characters');

            return self::FAILURE;
        }

        $users = MixpostAuth::getUserClass();
        $user = $users::where('email', $email)->first();

        if ($user) {
            $user->password = bcrypt($password);
            $user->save();
            $this->info("Administrator $email password synced from ADMIN_PASSWORD");

            return self::SUCCESS;
        }

        $users::create(['name' => 'Admin', 'email' => $email, 'password' => bcrypt($password)]);
        $this->info("Administrator $email created from ADMIN_PASSWORD");

        return self::SUCCESS;
    }
}
