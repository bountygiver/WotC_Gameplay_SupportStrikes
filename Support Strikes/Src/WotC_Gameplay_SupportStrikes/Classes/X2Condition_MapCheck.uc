//
// AUTHOR:	E3245
// DESC:	Checks current XCGS_BattleData and sees if a particular biome, plot, or parcel is loaded.
//			Fails if the current XCGS_BattleData contains any one of them.

class X2Condition_MapCheck extends X2Condition config (GameData);

var config array<string> DisallowedBiomes;
var config array<string> DisallowedPlots;
var config array<string> DisallowedParcels;

event name CallMeetsCondition(XComGameState_BaseObject kTarget)
{
	local XComGameState_BattleData BattleData;
	local StoredMapData_Parcel ParcelComp;

	BattleData = XComGameState_BattleData(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_BattleData'));

	if (DisallowedBiomes.Length > 0)
		if (DisallowedBiomes.Find(BattleData.MapData.Biome) != INDEX_NONE)
			return 'AA_MustBeOutdoors';

	if (DisallowedPlots.Length > 0)
		if (DisallowedPlots.Find(BattleData.MapData.PlotMapName) != INDEX_NONE)
			return 'AA_MustBeOutdoors';

	if (DisallowedParcels.Length > 0)
		foreach BattleData.MapData.ParcelData(ParcelComp)
			if (DisallowedParcels.Find(ParcelComp.MapName) != INDEX_NONE)
				return 'AA_MustBeOutdoors';

	return 'AA_Success';
}