<?PHP

namespace configurations;

use Knight\Lock;

use Knight\armor\Navigator as Define;

defined('ENVIRONMENT_FORCE_IP') or define('ENVIRONMENT_FORCE_IP', null);

final class Navigator
{
	use Lock;

	const PARAMETERS = [
		// force IP for development for remote identity and access management (set null in production)
		Define::CONFIGURATION_FORCE_IP => ENVIRONMENT_FORCE_IP,
		// force depth
		Define::CONFIGURATION_DEPTH => 2
	];
}
