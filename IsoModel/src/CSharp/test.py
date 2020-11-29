import clr
clr.AddReferenceToFileAndPath(r"isomodel.dll")

import sys
if '.' not in sys.path:
    sys.path.append('.')

import ISOModel

user_model = ISOModel.UserModel()
user_model.load("./test_data/defaults_test_building.ism", "./test_data/defaults_test_defaults.ism")
monthly_model = user_model.toMonthlyModel()
results = monthly_model.simulate()
for result in results:
  print(result.getEndUse(ISOModel.isomodel.ElecCool))

print(ISOModel.isomodel.totalEnergyUse(results))

user_model = ISOModel.UserModel()
user_model.load("./test_data/defaults_test_building.ism", "./test_data/defaults_test_defaults.ism")
hourly_model = user_model.toHourlyModel()
results = hourly_model.simulate()
for result in results:
  print(result.getEndUse(ISOModel.isomodel.ElecCool))

print(ISOModel.isomodel.totalEnergyUse(results))