Change Log
==========

Version 4.1.0 *(20th July, 2020)*
---------------------------------
*(Supports ComScore 6.0.0+)*
  * [Minor Fix] Remove references to `configuration.labels`, which SCORStreamingAnalytics class no longer exposes.

Version 4.1.0 *(23rd June, 2020)*
---------------------------------
* [Minor Feature] Default value is now `0` when total length property is missing.

Version 4.0.2 *(22nd June, 2020)*
---------------------------------
* [Fix] Issue where types that didn't respond to length would crash.
* [Fix] Unpinned analytics-ios dependency.

Version 4.0.1 *(30th March, 2020)*
-------------------------------------------
*(Supports ComScore 6.0.0)*
  * [New Feature] Serializes array and number Segment trait values 
  before mapping to Comscore.

Version 4.0.0-beta *(9th January, 2020)*
-------------------------------------------
*(Supports ComScore 6.0.0)*
  * [Major Update](https://github.com/segment-integrations/analytics-ios-integration-comscore/commit/1b11c0fbd78b17ceb95cf574758ed6120e361728): Migrate to ComScore v6.

Version 3.1.0-beta *(8th November, 2019)*
-------------------------------------------
*(Supports analytics-ios 3.7+ and ComScore 5.8.7+)*
  * [Fix] Supports integration-specific options under the key `com-score` in `options.integrations`.

Version 3.0.0 *(6th June, 2017)*
-------------------------------------------
*(Supports analytics-ios 3.0+ and ComScore 5.0+)*
  * [New Feature](https://github.com/segment-integrations/analytics-ios-integration-comscore/commit/0eec83a27db29aca06f66af896633f637336a1bb): Adds Video Tracking functionality.

Version 2.0.0 *(16th May, 2017)*
-------------------------------------------
*(Supports analytics-ios 3.0+ and ComScore 5.0+)*
  * [Major Update](https://github.com/segment-integrations/analytics-ios-integration-comscore/pull/10/commits/ccc7c81ae006e5b00bfd76c0d0f9bf4ded05c719): Migrates to comScore v5.


Version 1.0.2 *(7th December, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0+ and ComScore 3.1607.27)*
  * [Fix](https://github.com/segment-integrations/analytics-ios-integration-comscore/pull/3/commits/f658b1ef399c41f4f8120602eb0457676cadd815): Mismatched comScore key.
  * [Fix](https://github.com/segment-integrations/analytics-ios-integration-comscore/pull/3/commits/b98d1b3a66e5bb6dafaeb2c669b01a5fa90a16bb): NSLogv crash.

Version 1.0.1 *(18th September, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0+ and ComScore 3.1607.27)*

Updates ComScore SDK

Version 1.0.0 *(15th June, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.+ and ComScore 3.1510.231)*

Relax analytics-ios requirement.


Version 0.4.0 *(20th May, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0.+ and ComScore 3.1510.231)*

Rename CustomerC2 setting for consistency across platforms.

Version 0.3.0 *(20th May, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0.+ and ComScore 3.1510.231)*

Refactor autoUpdate settings to be more clear.

Version 0.2.0 *(19th May, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0.+ and ComScore 3.1510.231)*

Adds support for App Name setting.

Version 0.1.0 *(18th May, 2016)*
-------------------------------------------
*(Supports analytics-ios 3.0.+ and ComScore 3.1510.231)*

Initial release.
