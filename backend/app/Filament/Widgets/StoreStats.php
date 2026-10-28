<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class StoreStats extends StatsOverviewWidget
{
    protected static ?int $sort = 1;

    protected function getStats(): array
    {
        $revenueToday = Order::whereDate('created_at', today())->where('status', '!=', 'cancelled')->sum('total');
        $ordersToday = Order::whereDate('created_at', today())->count();
        $pending = Order::where('status', 'pending')->count();
        $newCustomers = User::where('is_admin', false)->where('created_at', '>=', now()->subDays(7))->count();
        $lowStock = Product::where('stock_quantity', '<', 20)->count();

        return [
            Stat::make('Revenue today', '$'.number_format($revenueToday, 2))
                ->description($ordersToday.' orders today')
                ->icon('heroicon-o-banknotes')
                ->color('success'),
            Stat::make('Pending orders', $pending)
                ->description('Waiting for confirmation')
                ->icon('heroicon-o-clock')
                ->color($pending ? 'warning' : 'gray'),
            Stat::make('New customers', $newCustomers)
                ->description('Last 7 days')
                ->icon('heroicon-o-user-plus')
                ->color('info'),
            Stat::make('Low stock products', $lowStock)
                ->description('Fewer than 20 left')
                ->icon('heroicon-o-exclamation-triangle')
                ->color($lowStock ? 'danger' : 'success'),
        ];
    }
}
