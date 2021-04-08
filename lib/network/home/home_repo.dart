/*This file is part of Medito App.

Medito App is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Medito App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with Medito App. If not, see <https://www.gnu.org/licenses/>.*/

import 'package:Medito/network/home/menu_response.dart';
import 'package:Medito/network/home/shortcuts_response.dart';
import 'package:Medito/viewmodel/auth.dart';
import 'package:Medito/viewmodel/http_get.dart';

class HomeRepo {
  final _ext = 'items/menu';

  Future<MenuResponse> fetchMenu() async {
    final response = await httpGet(baseUrl + _ext);
    return MenuResponse.fromJson(response);
  }
}
