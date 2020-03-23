//---------------------------------------------------------------------------------------
// AUTHOR:	E3245
// DESC:	Specific Heli Drop in conditions. 
//			Firstly, the GTS perk or whatever must have been bought.
//
//---------------------------------------------------------------------------------------
class X2Condition_HeliDropIn extends X2Condition config (GameData);

var config array<string> DisallowedBiomes;
var config array<string> DisallowedPlots;
var config array<string> DisallowedParcels;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_SupportStrikeManager				SupportStrikeMgr;

	SupportStrikeMgr = XComGameState_SupportStrikeManager(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_SupportStrikeManager'));
	if (SupportStrikeMgr == none)
		return 'AA_UnknownError';

	if (!SupportStrikeMgr.bEnableVagueOrders)
		return 'AA_AbilityUnavailable';

	return 'AA_Success';
}