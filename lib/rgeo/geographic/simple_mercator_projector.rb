# -----------------------------------------------------------------------------
# 
# Simple mercator projection
# 
# -----------------------------------------------------------------------------
# Copyright 2010 Daniel Azuma
# 
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# * Redistributions of source code must retain the above copyright notice,
#   this list of conditions and the following disclaimer.
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
# * Neither the name of the copyright holder, nor the names of any other
#   contributors to this software, may be used to endorse or promote products
#   derived from this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# -----------------------------------------------------------------------------
;


module RGeo
  
  module Geographic
    
    
    class SimpleMercatorProjector  # :nodoc:
      
      EQUATORIAL_RADIUS = 6378137.0
      
      
      def initialize(geography_factory_, opts_={})
        @geography_factory = geography_factory_
        @projection_factory = Cartesian.preferred_factory(:srid => 3857, :proj4 => '+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs', :buffer_resolution => opts_[:buffer_resolution], :lenient_multi_polygon_assertions => opts_[:lenient_multi_polygon_assertions], :has_z_coordinate => opts_[:has_z_coordinate], :has_m_coordinate => opts_[:has_m_coordinate])
      end
      
      
      def projection_factory
        @projection_factory
      end
      
      
      def project(geometry_)
        case geometry_
        when Feature::Point
          rpd_ = ImplHelper::Math::RADIANS_PER_DEGREE
          radius_ = EQUATORIAL_RADIUS
          @projection_factory.point(geometry_.x * rpd_ * radius_,
            ::Math.log(::Math.tan(::Math::PI / 4.0 + geometry_.y * rpd_ / 2.0)) * radius_)
        when Feature::Line
          @projection_factory.line(project(geometry_.start_point), project(geometry_.end_point))
        when Feature::LinearRing
          @projection_factory.linear_ring(geometry_.points.map{ |p_| project(p_) })
        when Feature::LineString
          @projection_factory.line_string(geometry_.points.map{ |p_| project(p_) })
        when Feature::Polygon
          @projection_factory.polygon(project(geometry_.exterior_ring),
                                      geometry_.interior_rings.map{ |p_| project(p_) })
        when Feature::MultiPoint
          @projection_factory.multi_point(geometry_.map{ |p_| project(p_) })
        when Feature::MultiLineString
          @projection_factory.multi_line_string(geometry_.map{ |p_| project(p_) })
        when Feature::MultiPolygon
          @projection_factory.multi_polygon(geometry_.map{ |p_| project(p_) })
        when Feature::GeometryCollection
          @projection_factory.collection(geometry_.map{ |p_| project(p_) })
        else
          nil
        end
      end
      
      
      def unproject(geometry_)
        case geometry_
        when Feature::Point
          dpr_ = ImplHelper::Math::DEGREES_PER_RADIAN
          radius_ = EQUATORIAL_RADIUS
          @geography_factory.point(geometry_.x / radius_ * dpr_,
            (2.0 * ::Math.atan(::Math.exp(geometry_.y / radius_)) - ::Math::PI / 2.0) * dpr_)
        when Feature::Line
          @geography_factory.line(unproject(geometry_.start_point), unproject(geometry_.end_point))
        when Feature::LinearRing
          @geography_factory.linear_ring(geometry_.points.map{ |p_| unproject(p_) })
        when Feature::LineString
          @geography_factory.line_string(geometry_.points.map{ |p_| unproject(p_) })
        when Feature::Polygon
          @geography_factory.polygon(unproject(geometry_.exterior_ring),
                                    geometry_.interior_rings.map{ |p_| unproject(p_) })
        when Feature::MultiPoint
          @geography_factory.multi_point(geometry_.map{ |p_| unproject(p_) })
        when Feature::MultiLineString
          @geography_factory.multi_line_string(geometry_.map{ |p_| unproject(p_) })
        when Feature::MultiPolygon
          @geography_factory.multi_polygon(geometry_.map{ |p_| unproject(p_) })
        when Feature::GeometryCollection
          @geography_factory.collection(geometry_.map{ |p_| unproject(p_) })
        else
          nil
        end
      end
      
      
      def wraps?
        true
      end
      
      
      def limits_window
        @limits_window ||= ProjectedWindow.new(@geography_factory, -20037508.342789, -20037508.342789, 20037508.342789, 20037508.342789, :is_limits => true)
      end
      
      
    end
    
    
  end
  
end
