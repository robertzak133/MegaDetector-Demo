//
//  ViewfinderViewLocal.swift
//  WBWL Trail Camera
//
//  Created by Bob Zak on 12/11/23.
//

/*
See the License.txt file for this sample’s licensing information.
*/

import SwiftUI

struct ViewfinderView: View {
    var image: Image
    
    var body: some View {
        GeometryReader { geometry in
            image
                .resizable()
                .scaledToFill()
                .frame(width: geometry.size.width, height: geometry.size.height)
        }
    }
}


struct ViewfinderView_Previews: PreviewProvider {
    static var previews: some View {
        ViewfinderView(image: Image("ViewfindViewPreview"))
    }
}


